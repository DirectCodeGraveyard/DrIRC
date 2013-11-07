module irc.config;

public import std.socket;

/**
 * Base class for setting up a connection to the IRC server
 * Authors: samrg472
 */
public class IRCConfig {

    public immutable string nickname;
    public immutable string username;
    public immutable string realname;
    
    @property public Address address() { return _address; }
    private Address _address;

    public this(string nick, string username, string realname, Address address) {
        this.nickname = nick.idup;
        this.username = username.idup;
        this.realname = realname.idup;
        this._address = address;
    }

}