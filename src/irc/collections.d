module irc.collections;

import std.algorithm;

public class List(T) {

    @property public size_t length() { return realLength; }
    private immutable bool allowDuplicates;
    private T[] contents;

    private size_t appendLength;
    private size_t realLength;

    public this(bool allowDuplicates = false, size_t appendLength = 10) {
        this.allowDuplicates = allowDuplicates;
        this.appendLength = appendLength;
    }

    public bool add(T t) {
        if (t is null)
            return false;

        size_t pos = -1;
        for (size_t i = 0; i < contents.length; i++) {
            if ((pos == -1) && (contents[i] is null)) {
                pos = i;
                if (allowDuplicates)
                    break;
            } else if (!allowDuplicates && contents[i] && (contents[i] == t))
                return false;
        }

        if (pos == -1) {
            size_t prevInt = contents.length;
            contents.length += appendLength;
            pos = prevInt;
        }
        contents[pos] = t;
        realLength++;
        return true;
    }

    public bool contains(T t) {
        return contents.countUntil(t) > -1;
    }

    public T opOpAssign(string op : "+")(T t) {
        add(t);
        return t;
    }

    /**
     * Safe collection getter (array-bounds safe)
     */
    public T get(size_t i) {
        if ((i < 0) || (i >= contents.length))
            return null;
        return contents[i];
    }

    public T remove(size_t i) {
        if ((i < 0) || (i >= contents.length))
            return null;
        T temp = contents[i];
        contents[i] = null;
        realLength--;
        return temp;
    }

    public T remove(T t) {
        if (t is null)
            return null;
        size_t index = contents.countUntil(t);
        if (index > -1)
            return remove(index);
        return null;
    }

    /**
     * Array index overload (array-bounds safe)
     */
    T opIndex(size_t index) {
        return get(index);
    }
}
