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
            if ((cast(uint) pos == -1) && (contents[cast(uint) i] is null)) {
                pos = cast(long) i;
                if (allowDuplicates)
                    break;
            } else if (!allowDuplicates && contents[cast(uint) i] && (contents[cast(uint) i] == t))
                return false;
        }

        if (pos == -1) {
            long prevInt = cast(long) contents.length;
            contents.length += cast(uint) relocateLength;
            pos = prevInt;
        }
        contents[cast(uint) pos] = t;
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
        return contents[cast(uint) i];
    }

    public T remove(long i) {
        if ((cast(uint) i < 0) || (i >= contents.length))
            return null;
        T temp = contents[cast(uint) i];
        contents[cast(uint) i] = null;
        realLength--;
        return temp;
    }

    public T remove(T t) {
        if (t is null)
            return null;
        long index = contents.countUntil(t);
        if (cast(uint) index > -1)
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
