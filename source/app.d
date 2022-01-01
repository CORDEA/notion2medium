import std.stdio;
import std.string;
import std.file;
import std.path;
import std.array;
import std.format;
import std.algorithm.searching;
import std.process;
import std.net.curl;
import std.json;
import std.regex;
import std.ascii;

void main(string[] args)
{
    assert(args.length > 1, "Notion's markdown is required.");
    auto filename = args[1];
    assert(exists(filename), "Notion's markdown is required.");
    auto token = environment.get("GITHUB_TOKEN");
    assert(token, "GitHub API token is required.");
    auto content = readText(filename);
    auto parsed = parseContent(content.split(newline));

    auto medium = appender!string();
    foreach (Content c; parsed)
    {
        if (Code code = cast(Code) c)
        {
            auto id = createGist(code, filename, token);
            medium ~= "https://carbon.now.sh/";
            medium ~= id;
            medium ~= newline;
        }
        else
        {
            medium ~= c.values().join(newline);
        }
    }
    write(medium[]);
}

string createGist(Code code, string filename, string token)
{
    auto http = HTTP();
    http.method = HTTP.Method.post;
    http.url = "https://api.github.com/gists";
    http.addRequestHeader("Authorization", "token %s".format(token));
    http.addRequestHeader("Accept", "application/vnd.github.v3+json");

    auto name = filename.baseName().setExtension(code.langCode() is null ? "txt" : code.langCode());
    JSONValue file = JSONValue([
        name: JSONValue(["content": code.values().join(newline)])
    ]);
    JSONValue json = JSONValue(["files": file]);
    http.setPostData(json.toString(), "application/json");

    HTTP.StatusLine status;
    auto response = appender!(ubyte[])();
    http.onReceive = (data) { response ~= data; return data.length; };
    http.onReceiveStatusLine = (l) { status = l; };
    http.perform();

    assert(status.code == 201);
    auto parsed = parseJSON(cast(char[])(response[]));
    return parsed["id"].str;
}

Content[] parseContent(string[] lines)
{
    auto linkRegex = regex(r"\[[^\]]+\]\(([^\)]+)\)");
    auto inCode = false;
    auto lang = "";
    auto currentLines = appender!(string[])();
    auto result = appender!(Content[])();
    foreach (line; lines)
    {
        if (line.startsWith("```"))
        {
            auto l = array(currentLines[]);
            if (l.length > 0)
            {
                if (inCode)
                {
                    result ~= new Code(l, lang);
                }
                else
                {
                    result ~= new Text(l);
                }
            }
            currentLines.clear();
            inCode = !inCode;
            lang = line.length > 3 ? line[3 .. $] : null;
            continue;
        }
        if (inCode)
        {
            currentLines ~= line;
        }
        else
        {
            currentLines ~= line.replaceAll(linkRegex, "$1");
        }
    }
    auto l = currentLines[];
    if (l.length > 0)
    {
        result ~= new Text(l);
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
