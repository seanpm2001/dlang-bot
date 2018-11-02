module dlangbot.scaleway_api;

import std.algorithm;
import std.array : array, empty, front;
import std.datetime.systime;
import std.string : format;

import vibe.core.log : logError, logInfo;
import vibe.data.json : byName, Name = name, deserializeJson, serializeToJson, Json;
import vibe.http.common : enforceHTTP, HTTPMethod, HTTPStatus;
import vibe.stream.operations : readAllUTF8;

import dlangbot.utils : request;

string scalewayAPIURL = "https://dp-par1.scaleway.com";
string scalewayAuth;

//==============================================================================
// Scaleway (Bare Metal) servers
//==============================================================================

struct Server
{
    string id, name;
    enum State { running, stopped }
    @byName State state;

    enum Action { poweron, poweroff, terminate }

    void action(Action action)
    {
        import std.conv : to;
        scwPOST("/servers/%s/action".format(id), ["action": action.to!string]).dropBody;
    }
}

struct Image
{
    string id, name, organization;
    @Name("creation_date") SysTime creationDate;
}

Server[] servers()
{
    return scwGET("/servers")
        .readJson["servers"]
        .deserializeJson!(Server[]);
}

Server createServer(string name, string commercialType, Image image)
{
    auto payload = serializeToJson([
            "organization": image.organization,
            "name": name,
            "image": image.id,
            "commercial_type": commercialType]);
    payload["enable_ipv6"] = true;
    return scwPOST("/servers", payload)
        .readJson["server"]
        .deserializeJson!Server;
}

Image[] images()
{
    return scwGET("/images")
        .readJson["images"]
        .deserializeJson!(Image[]);
}

private:

auto scwGET(string path)
{
    return request(scalewayAPIURL ~ path, (scope req) {
        req.headers["X-Auth-Token"] = scalewayAuth;
    });
}

auto scwPOST(T)(string path, T arg)
{
    return request(scalewayAPIURL ~ path, (scope req) {
        req.headers["X-Auth-Token"] = scalewayAuth;
        req.method = HTTPMethod.POST;
        req.writeJsonBody(arg);
    });
}
