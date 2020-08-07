proc decode_op {code} {
    set nib3 [expr {($code & 0xf000) >> 12}]
    set x [expr {($code & 0xf00) >> 8}]
    set y [expr {($code & 0xf0) >> 4}]
    set nib0 [expr {$code & 0xf}]

    set nnn [expr {$code & 0xfff}]
    set kk [expr {$code & 0xff}]

    return [switch -regexp [list $nib3 $x $y $nib0] {
        {^0 0 14 0$}            { list Cls }
        {^0 0 14 14$}           { list Ret }
        {^0 \d+ \d+ \d+$}       { list Sys $nnn }
        {^1 \d+ \d+ \d+$}       { list Jmp $nnn }
        {^2 \d+ \d+ \d+$}       { list Call $nnn }
        {^3 \d+ \d+ \d+$}       { list Se $x $kk }
        {^4 \d+ \d+ \d+$}       { list Sne $x $kk }
        {^5 \d+ \d+ 0$}         { list Sre $x $y }
        {^6 \d+ \d+ \d+$}       { list Ld $x $kk }
        {^7 \d+ \d+ \d+$}       { list Add $x $kk }
        {^8 \d+ \d+ 0$}         { list Mov $x $y }
        {^8 \d+ \d+ 1$}         { list Or $x $y }
        {^8 \d+ \d+ 2$}         { list And $x $y }
        {^8 \d+ \d+ 3$}         { list Xor $x $y }
        {^8 \d+ \d+ 4$}         { list Addr $x $y }
        {^8 \d+ \d+ 5$}         { list Subr $x $y }
        {^8 \d+ \d+ 6$}         { list Shr $y $x }
        {^8 \d+ \d+ 7$}         { list Subnr $x $y }
        {^8 \d+ \d+ 14$}        { list Shl $y $x }
        {^9 \d+ \d+ 0$}         { list Srne $x $y }
        {^10 \d+ \d+ \d+$}      { list Ldi $nnn }
        {^11 \d+ \d+ \d+$}      { list Jmpi $nnn }
        {^12 \d+ \d+ \d+$}      { list Rand $x $kk }
        {^13 \d+ \d+ \d+$}      { list Draw $x $y $nib0 }
        {^14 \d+ 9 14$}         { list Skp $x }
        {^14 \d+ 10 1$}         { list Sknp $x }
        {^15 \d+ 0 7$}          { list Movd $x }
        {^15 \d+ 0 10$}         { list Key $x }
        {^15 \d+ 1 5$}          { list Ldd $x }
        {^15 \d+ 1 8$}          { list Lds $x }
        {^15 \d+ 1 14$}         { list Addi $x }
        {^15 \d+ 2 9$}          { list Ldspr $x }
        {^15 \d+ 3 3$}          { list Bcd $x }
        {^15 \d+ 5 5$}          { list Str $x }
        {^15 \d+ 6 5$}          { list Read $x }
    }]
}
