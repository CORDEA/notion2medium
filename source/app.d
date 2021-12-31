import std.stdio;
import std.file;
import std.array;
import std.format;
import std.algorithm.searching;

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
    auto parsed = parseContent(content.split());
}

private Content[] parseContent(string[] lines)
{
    auto inCode = false;
    auto currentLines = appender!(string[])([]);
    auto result = appender!(Content[])([]);
    foreach (string line; lines)
    {
        if (line.startsWith("```"))
        {
            auto lang = line[3 .. $];
            auto l = array(currentLines[]);
            if (l.length > 0)
            {
                if (inCode)
                {
                    result.put(new Code(l, lang));
                }
                else
                {
                    result.put(new Text(l));
                }
            }
            currentLines.clear();
            inCode = !inCode;
            continue;
        }
        currentLines.put(line);
    }
    auto l = currentLines[];
    if (l.length > 0)
    {
        result.put(new Text(l));
    }
    return result[];
}

class Content
{
    private string[] lines;

    this(string[] lines)
    {
        this.lines = lines;
    }

    string[] values()
    {
        return lines;
    }
}

class Text : Content
{
    this(string[] lines)
    {
        super(lines);
    }
}

class Code : Content
{
    private string lang;

    this(string[] lines, string lang)
    {
        super(lines);
        this.lang = lang;
    }

    string langCode()
    {
        return lang;
    }
}
