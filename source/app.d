import std.stdio;
import std.file;

void main(string[] args)
{
    if (args.length < 2)
    {
        return;
    }
    auto filename = args[1];
    if (!exists(filename))
    {
        return;
    }
    auto content = readText(filename);
    writeln(content);
}
