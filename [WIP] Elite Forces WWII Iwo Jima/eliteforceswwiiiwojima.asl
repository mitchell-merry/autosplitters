state("client")
{
    string32 map: "object.lto", 0xE0E33;
    string32 map2: "cshell.dll", 0x10CF33;
}

update
{
    if (old.map != current.map)
    {
        print("map: " + old.map + " -> " + current.map);
    }
}

onStart
{
    print("map: " + current.map);
}

