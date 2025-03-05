BEGIN {
    print "dna,binding"
}

# Process background file (first file)
FNR==NR {
    if (!/^>/) {
        gsub(/[[:space:]]/,"")
        if (length($0) > 0) {
            print $0 ",0"
        }
    }
    next
}

# Process foreground file (second file)
!/^>/ {
    gsub(/[[:space:]]/,"")
    if (length($0) > 0) {
        print $0 ",1"
    }
}
