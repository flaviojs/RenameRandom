import std.stdio, std.cstream;
import std.file;
import std.string;
import std.regex;
import std.random;


string ask_dir() {
	writeln("Directory: (leave empty to use the current directory)");
	string dir = strip(readln());
	if (dir == "")
		dir = getcwd();
	return(dir);
}


char ask_rename(string[] filenames) {
	for (;;) {
		writeln("Are you sure you want to rename the files? (Yes/No/List)");
		string answer = tolower(strip(readln()));
		if (answer == "y" || answer == "yes")
			return 'y';
		else if (answer == "n" || answer == "no")
			return 'n';
		else if (answer == "l" || answer == "list")
		{
			foreach (filename; filenames)
				writeln(filename);
		}
		else
			writeln("ERROR - unrecognized answer \"", answer, "\"");
	}
}


int do_exit(int ret) {
	writeln("Press <ENTER> to exit");
	din.getc();
	return(ret);
}


int main(string[] args)
{
	writeln("File rename utility.  Flavio J. Saraiva @ 2011-11-08");
	writeln("https://github.com/flaviojs/RenameRandom");
	writeln();
	writeln("Usage: RenameRandom [dir1 dir2 ...]");
	writeln();
	writeln("Asks for a directory is none is given as an argument.");
	writeln("Searches for files named \"<anything><number>.<anything>\" in the directories.");
	writeln("Renames the numeric part to a unique random number in the range [1,numfiles].");
	writeln("Logs to RenameRandom.csv as \"<oldfilename>\",\"<newfilename>\"");
	writeln();
	writeln();

	string[] dirs;
	if (args.length >= 2)
		dirs = args[1..$];
	else
		dirs ~= ask_dir();
	foreach (dir; dirs)
	{
		if (!isDir(dir))
		{
			writeln("ERROR - ", dir, " is not a directory");
			return(do_exit(1));
		}
		writeln("Directory ",dir);
	}

	writeln("Searching for files...");
	auto r = regex(r"^(.*)(\d+)(\.[^\.\\/]*)$");
	string[] filenames;
	foreach (dir; dirs) {
		foreach (string filename; dirEntries(dir, SpanMode.depth))
		{
			if (!isFile(filename))
				continue;
			auto m = match(filename, r);
			if (m.empty)
				continue;
			filenames ~= filename;
		}
	}
	writeln("Found ", filenames.length, " files");

	if (filenames.length > 0 && ask_rename(filenames) == 'y') {
		writeln("Renaming files...");
		string csv = "RenameRandom.csv";
		auto dquote = regex("(\")", "g");
		string[] newfilenames;
		int[] numbers;
		for (int num = 1; num <= filenames.length; ++num)
			numbers ~= num;
		auto rnd = Random(unpredictableSeed);
		if (exists(csv))
			std.file.write(csv,"");
		for (auto i = 0; i < filenames.length; ++i) {
			string filename = filenames[i];
			auto numidx = uniform(0, numbers.length, rnd);
			int num = numbers[numidx];
			numbers[numidx] = numbers[numbers.length - 1];
			numbers.length = numbers.length - 1;
			string newfilename = replace(filename, r, format("$01%d$03", num));
			newfilenames ~= newfilename;
			string csvline = format("\"%s\",\"%s\"\r\n",
				replace(filename, dquote, "\"\""),
				replace(newfilename, dquote, "\"\""));
			std.file.append(csv, csvline);
		}
		for (auto i = 0; i < filenames.length; ++i) {
			string filename = filenames[i];
			string newfilename = newfilenames[i];
			for (auto j = i + 1; j < filenames.length; ++j) {
				if (filenames[j] == newfilename) {
					string tmpfilename = replace(newfilename, r, "$01$02_$03");
					writeln(newfilename, " -> ", tmpfilename);
					rename(newfilename, tmpfilename);
					filenames[j] = tmpfilename;
					break;
				}
			}
			writeln(filename, " -> ", newfilename);
			rename(filename, newfilename);
		}
		writeln("DONE");
	}

	return(do_exit(0));
}
