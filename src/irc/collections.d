module irc.collections;

import std.algorithm;

public class List(T) {

    @property public ulong length() { return realLength; }
    private immutable bool allowDuplicates;
    private T[] contents;

    private ulong relocateLength;
    private ulong realLength;

    public this(bool allowDuplicates = false, int relocateLength = 10) {
        this.allowDuplicates = allowDuplicates;
        this.relocateLength = relocateLength;
    }

    public bool add(T t) {
        if (t is null)
            return false;

        long pos = -1;
        for (long i = 0; i < contents.length; i++) {
            if ((pos == -1) && (contents[i] is null)) {
                pos = i;
                if (allowDuplicates)
                    break;
            } else if (!allowDuplicates && contents[i] && (contents[i] == t))
                return false;
        }

        if (pos == -1) {
            ulong prevInt = contents.length;
            contents.length += relocateLength;
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
    public T get(long i) {
        if ((i < 0) || (i >= contents.length))
            return null;
        return contents[i];
    }

    public T remove(long i) {
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
        long index = contents.countUntil(t);
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
