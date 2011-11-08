import std.stdio, std.cstream;
import std.file;
import std.string;
import std.regex;
import std.random;


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
	writeln("File rename utility.  Flavio J. Saraiva @ 2011-11-04");
	writeln("https://github.com/flaviojs/RenameRandom");
	writeln();
	writeln("Searches for files named \"<anything><number>.<anything>\" in a directory.");
	writeln("Renames the numeric part of each file to a unique random number in the range [1,numfiles]");
	writeln();

	writeln("Directory: (leave empty to use the current directory)");
	string dir = strip(readln());
	if (dir == "")
		dir = getcwd();
	if ( !isDir(dir) ) {
		writeln("ERROR - ", dir, " is not a directory");
		return(do_exit(1));
	}
	writeln("Work directory is ",dir);

	writeln("Searching for files...");
	auto r = regex(r"^(.*)(\d+)(\.[^\.\\/]*)$");
	string[] filenames;
	foreach (string filename; dirEntries(dir, SpanMode.depth))
	{
		if (!isFile(filename))
			continue;
		auto m = match(filename, r);
		if (m.empty)
			continue;
		filenames ~= filename;
	}
	writeln("Found ", filenames.length, " files");

	if (filenames.length > 0 && ask_rename(filenames) == 'y') {
		writeln("Renaming files...");
		string[] newfilenames;
		int[] numbers;
		for (int num = 1; num <= filenames.length; ++num)
			numbers ~= num;
		auto rnd = Random(unpredictableSeed);
		for (auto i = 0; i < filenames.length; ++i) {
			string filename = filenames[i];
			auto numidx = uniform(0, numbers.length, rnd);
			int num = numbers[numidx];
			numbers[numidx] = numbers[numbers.length - 1];
			numbers.length = numbers.length - 1;
			newfilenames ~= replace(filename, r, format("$01%d$03", num));
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
