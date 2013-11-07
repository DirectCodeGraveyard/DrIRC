module irc.exceptions;

public class IllegalStateException : Exception {

    public this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(message, file, line, next);
    }
}

public class NullPointerException : Exception {

    public this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(message, file, line, next);
    }
}