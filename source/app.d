import std.stdio;
import std.file;
import std.path;
import std.array;
import std.format;
import std.algorithm.searching;
import std.json;

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
    foreach (Content c; parsed)
    {
        if (Code code = cast(Code) c)
        {
            createGist(code, filename, "");
        }
    }
}

void createGist(Code code, string filename, string token)
{
    auto name = filename.baseName().setExtension(code.langCode() is null ? "txt" : code.langCode());
    JSONValue file = JSONValue([
        name: JSONValue(["content": code.values().join("\n")])
    ]);
    JSONValue json = JSONValue(["files": file]);
}

Content[] parseContent(string[] lines)
{
    auto inCode = false;
    auto lang = "";
    auto currentLines = appender!(string[])([]);
    auto result = appender!(Content[])([]);
    foreach (string line; lines)
    {
        if (line.startsWith("```"))
        {
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
            lang = line.length > 3 ? line[3 .. $] : null;
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
