module irc.irc;

public import irc.utils;
public import irc.config;
public import irc.events;

import std.regex;
import std.string;
import irc.exceptions;

/**
 * Primary class for interacting with an IRC server
 * Standards: Conforms to RFC 2812
 * See_Also: <href>http://tools.ietf.org/html/rfc2812</href>
 * Authors: samrg472
 */
public class IRCBot {

    private enum pattern = regex(`^(?:[:](\S+) )?(\S+)(?: (?!:)(.+?))?(?: [:](.+))?$`);

    @property public bool isConnected() { return connected && socket !is null; }
    @property public string nick() { return currentNick; }

    public {
        // Returning null signifies the event was already posted
        @property EventHandler!ReadyEvent readyEventHandler() { return _readyEventHandler; }

        @property EventHandler!RawEvent rawEventHandler() { return _rawEventHandler; }
        @property EventHandler!MessageEvent messageEventHandler() { return _messageEventHandler; }
        @property EventHandler!JoinChanEvent joinChanEventHandler() { return _joinChanEventHandler; }
        @property EventHandler!PartChanEvent partChanEventHandler() { return _partChanEventHandler; }
        @property EventHandler!KickEvent kickEventHandler() { return _kickEventHandler; }
        @property EventHandler!NickChangeEvent nickChangeEventHandler() { return _nickChangeEventHandler; }
    }

    private {
        IRCConfig config;

        // Socket data
        TcpSocket socket;
        char[] chars = null;
        bool connected = false;
    }

    private {
        // Events
        EventHandler!RawEvent        _rawEventHandler;
        EventHandler!MessageEvent    _messageEventHandler;
        EventHandler!ReadyEvent      _readyEventHandler;
        EventHandler!JoinChanEvent   _joinChanEventHandler;
        EventHandler!PartChanEvent   _partChanEventHandler;
        EventHandler!KickEvent       _kickEventHandler;
        EventHandler!NickChangeEvent _nickChangeEventHandler;
    }

    private {
        // NickServ
        char[] authNick = null;
        char[] authCommand = null;
        char[] authPassword = null;
    }

    private {
        // Cache
        Channel[string] channels;
        string currentNick;
    }

    /**
     * Constructs thie bot based on the configuration
     */
    public this(IRCConfig config) {
        assert(config, "config parameter is null");
        this.config = config;
        this.currentNick = config.nickname;
        _rawEventHandler        = new BotEventHandler!RawEvent(this);
        _messageEventHandler    = new BotEventHandler!MessageEvent(this);
        _readyEventHandler      = new BotEventHandler!ReadyEvent(this, false);
        _joinChanEventHandler   = new BotEventHandler!JoinChanEvent(this);
        _partChanEventHandler   = new BotEventHandler!PartChanEvent(this);
        _kickEventHandler       = new BotEventHandler!KickEvent(this);
        _nickChangeEventHandler = new BotEventHandler!NickChangeEvent(this);
    }

    /**
     * This should be called before the bot connects
     */
    public void authenticateNick(char[] password, char[] authNick = "NickServ".dup, 
                                                    char[] command = "identify".dup) {
        if (isConnected)
            throw new IllegalStateException("Attempted to setup automated nick auth when the bot is already connected");
        this.authPassword = password;
        this.authNick = authNick;
        this.authCommand = command;
    }

    public void connect(char[] serverPassword = null) {
        if (isConnected)
            return;
        socket = new TcpSocket(config.address);
        socket.blocking = false;
        connected = true;

        if (serverPassword)
            send(format("PASS %s", serverPassword));
        send(format("USER %s 0 0: %s", config.username, config.realname));
        send(format("NICK %s", config.nickname));
    }

    /**
     * Completely close the connection from the IRC server rendering the instance useless for further use
     * An optional quit message can be provided
     */
    public void disconnect(immutable(char[]) msg = "") {
        if (!isConnected)
            return;
        send(format("QUIT %s", msg));
        socket.shutdown(SocketShutdown.BOTH);
        socket.close();

        connected = false;
        destroy(socket);
        socket = null;

        destroy(_readyEventHandler);
        _readyEventHandler = new BotEventHandler!ReadyEvent(this, false);
    }

    /**
     * Joins the specified channel
     */
    public void join(string channel) {
        send(format("JOIN %s", channel));
    }

    /**
     * Parts the specified channel
     */
    public void part(string channel) {
        send(format("PART %s", channel));
    }

    /**
     * Processes all the bot events and read data. This *MUST* be used in your application main loop in
     * order for the bot to function properly. This can be offloaded into another thread to automatically 
     * read all the data.
     * Examples:
     * -------------------
     * while (loop()) {}
     * -------------------
     * Returns: Whether the loop processing was successful; 
     * if false, you are (most likely) disconnected from the server
     */
    public bool loop() {
        if (!isConnected)
            throw new IllegalStateException("Attempted to process bot data in an unconnected state");
        
        if (chars is null)
            chars = new char[0];
        {
            char[] _char = new char[1];
            long status = socket.receive(_char);

            // Not sure why it returns ERROR and Successful at the same time
            if ((status == 0) || (status == Socket.ERROR && socket.getErrorText() == "Success"))
                return true;
            else if (status == Socket.ERROR)
                return false;

            if (_char[0] != '\n') {
                chars ~= _char;
                return true;
            }                
        }

        string line = chars.length ? chop(cast(string) chars) : null;
        chars = null;
        if (line) {
            auto m = line.match(IRCBot.pattern).captures;
            string[] s = new string[m.length];
            for (int i = 0; i < m.length; i++)
                s[i] = m[i];

            auto temp = s.idup;
            rawEventHandler.post(new RawEvent(this, line, temp));
            handleLine(temp);
        }
        return line !is null;
    }

    /**
     * Send raw data to the IRC server
     */
    public void send(immutable(char[]) data) {
        if (!isConnected)
            throw new IllegalStateException("Attempted to write from an unconnected bot");
        if (data is null)
            throw new NullPointerException("data is null");
        void[] buf = data.dup ~ "\r\n";
        socket.send(buf);
    }

    private void handleLine(immutable(char[][]) captures) {
        string command = captures[2];
        switch (command) {
            case "471": // ERR_CHANNELISFULL
            case "473": // ERR_INVITEONLYCHAN
            case "474": // ERR_BANNEDFROMCHAN
            case "475": // ERR_BADCHANNELKEY
            case "477": // ERR_NEEDREGGEDNICK
                channels[captures[3].split()[1]] = null;
                // TODO: Post an UnableToJoinChan event
                break;
            default:
        }
        switch (command) {
            case "PING":
                send("PONG " ~ captures[4]);
                break;
            case "PRIVMSG":
                messageEventHandler.post(new MessageEvent(this, captures[1], captures[3], captures[4]));
                break;
            case "376": // RPL_ENDMOTD
                if (readyEventHandler) {
                    if (authNick && authCommand && authPassword) {
                        send(format("PRIVMSG %s :%s %s", authNick, authCommand, authPassword));
                        authNick = authCommand = authPassword = null;
                    }
                    readyEventHandler.post(new ReadyEvent(this), true);

                    // Unregister everything
                    destroy(_readyEventHandler);
                    _readyEventHandler = null;
                }
                break;
            case "JOIN":
                // Disabled until Channel's cache something useful
                //if ((new User(this, captures[1])).user == currentNick)
                //    channels[captures[3]] = new Channel(this, captures[3]);
                _joinChanEventHandler.post(new JoinChanEvent(this, captures[3], captures[1]));
                break;
            case "PART":
                if ((new User(this, captures[1])).user == currentNick)
                    channels[captures[3]] = null;
                _partChanEventHandler.post(new PartChanEvent(this, captures[3], captures[1]));
                break;
            case "KICK":
                auto data = captures[3].split();
                if (data[1] == currentNick)
                    channels[data[0]] = null;
                _kickEventHandler.post(new KickEvent(this, captures[3], captures[1]));
                break;
            case "NICK":
                auto user = new User(this, captures[1]);
                if (user.user == currentNick)
                    currentNick = captures[4];
                auto builtHostMask = captures[4] ~ "!" ~ user.realname ~ "@" ~ user.hostmask;
                _nickChangeEventHandler.post(new NickChangeEvent(this, builtHostMask, user.user));
                break;
            default:
        }
    }
}
