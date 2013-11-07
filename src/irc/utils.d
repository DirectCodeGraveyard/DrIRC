module irc.utils;

import irc.irc;
import std.regex;
import std.string;

public class Target {

    @property public IRCBot bot() { return _bot; };
    public immutable string target;

    private IRCBot _bot;

    public this(IRCBot bot, string target) {
        this._bot = bot;
        this.target = target.idup;
    }

    public void sendMessage(string msg) {
        bot.send(format("PRIVMSG %s :%s", target, msg));
    }

    public void sendNotice(string msg) {
        bot.send(format("NOTICE %s :%s", target, msg));
    }
}

public class User : Target {

    private enum pattern = regex(`!~|!|@`);

    public immutable string user;
    public immutable string realname;
    public immutable string hostmask;

    /**
     * User is in form of *!*\@*
     */
    public this(IRCBot bot, string user) {
        auto captures = user.split(pattern);
        this.user = captures[0];
        this.realname = captures[1];
        this.hostmask = captures[2];
        super(bot, this.user);
    }
}

public class Channel : Target {

    public this(IRCBot bot, string target) {
        super(bot, target);
    }

    /**
     * Kicks the user from a channel with an optional reason
     */
    public void kick(string user, string reason = "") {
        bot.send(format("KICK %s %s :%s", target, user, reason));
    }

    /**
     * Set channel modes. Only provide the user if the channel mode requires it.
     * The provided user can be their nickname or hostmask.
     */
    public void setMode(string modes, string user = "") {
        bot.send(format("MODE %s %s %s", target, modes, user));
    }

    /**
     * The user can be their nickname or hostmask
     */
    public void unban(string user) {
        setMode("-b", user);
    }

    /**
     * The user can be their nickname or hostmask
     */
    public void ban(string user) {
        setMode("+b", user);
    }

    /**
     * All-in-one kickban with an optional reason
     */
    public void kickban(string user, string reason = "") {
        kick(user, reason);
        ban(user);
    }
}
