module irc.events;

import irc.irc;
import core.thread;
import std.signals;
import std.algorithm;
import irc.exceptions;
import irc.collections;


public class EventHandler(T : Event) {

    @property public ulong length() { return events.length; }
    private List!(void function(T)) events;

    public this() {
        events = new List!(void function(T));
    }

    public void register(void function(T) t) {
        events.add(t);
    }

    public void unregister(void function(T) t) {
        events.remove(t);
    }

    public void post(T e, bool join = false) {
        if (length == 0)
            return;
        auto t = new core.thread.Thread(() {
            for (ulong i = 0; i < length; i++) {
                auto temp = events[i];
                if (temp !is null)
                    temp(e);
            }
        });
        t.isDaemon = true;
        t.start();
        if (join)
            t.join();
    }
}

public class BotEventHandler(T : Event) : EventHandler!T {

    private IRCBot bot;
    private immutable bool postRegister;

    public this(IRCBot bot, bool postRegister = true) {
        this.bot = bot;
        this.postRegister = postRegister;
    }

    override public void register(void function(T) t) {
        if (!postRegister && bot.isConnected)
            throw new IllegalStateException("Attempting to register an event after the bot is connected");
        super.register(t);
    }
}

public abstract class Event {

    @property IRCBot bot() { return _bot; }
    private IRCBot _bot;

    public this(IRCBot bot) {
        this._bot = bot;
    }
}

private abstract class BaseChannelEvent : Event {

    @property public Channel channel() { return _channel; }
    @property public User user() { return _user; }

    private Channel _channel;
    private User _user;

    public this(IRCBot bot, string channel, string user) {
        super(bot);
        this._channel = new Channel(bot, channel);
        this._user = new User(bot, user);
    }
}

/**
 * This event is posted after every line read from the server
 */
public class RawEvent : Event {

    public immutable string message;
    public immutable string[] regexData;

    public this(IRCBot bot, string msg, immutable(char[][]) regexData) {
        super(bot);
        this.regexData = regexData.idup;
        message = msg.idup;
    }
}

/**
 * This event is posted after the first end of the MOTD, once posted, all events registered to this are unregistered
 */
public class ReadyEvent : Event {

    public this(IRCBot bot) {
        super(bot);
    }

}

/**
 * Posted whenever a message is received, whether its in a channel or private
 */
public class MessageEvent : Event {

    @property public User sender() { return _sender; }
    @property public Target target() { return _target; }

    public immutable string message;
    public immutable bool isPrivateMsg;

    private User _sender;
    private Target _target;

    public this(IRCBot bot, string sender, string target, string message) {
        super(bot);
        this._sender = new User(bot, sender);
        if (target[0] == '#') {
            this._target = new Channel(bot, target);
            this.isPrivateMsg = false;
        } else {
            this._target = this._sender;
            this.isPrivateMsg = true;
        }
        this.message = message.idup;
    }
}

public class JoinChanEvent : BaseChannelEvent {

    public this(IRCBot bot, string channel, string user) {
        super(bot, channel, user);
    }
}

public class PartChanEvent : BaseChannelEvent {

    public this(IRCBot bot, string channel, string user) {
        super(bot, channel, user);
    }
}

public class KickEvent : BaseChannelEvent {

    public this(IRCBot bot, string channel, string user) {
        super(bot, channel, user);
    }
}

public class NickChangeEvent : Event {

    @property User user() { return _user; }
    private User _user;

    public immutable string oldNick;

    public this(IRCBot bot, string user, string oldNick) {
        super(bot);
        this._user = new User(bot, user);
        this.oldNick = oldNick.idup;
    }
}
