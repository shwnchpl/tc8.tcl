package require Tcl 8.5
package require Tk

namespace eval c8 {
    variable FONT_SPRITES {
        0xf0 0x90 0x90 0x90 0xf0
        0x20 0x60 0x20 0x20 0x70
        0xf0 0x10 0xf0 0x80 0xf0
        0xf0 0x10 0xf0 0x10 0xf0
        0x90 0x90 0xf0 0x10 0x10
        0xf0 0x80 0xf0 0x10 0xf0
        0xf0 0x80 0xf0 0x90 0xf0
        0xf0 0x10 0x20 0x40 0x40
        0xf0 0x90 0xf0 0x90 0xf0
        0xf0 0x90 0xf0 0x10 0xf0
        0xf0 0x90 0xf0 0x90 0x90
        0xe0 0x90 0xe0 0x90 0xe0
        0xf0 0x80 0x80 0x80 0xf0
        0xe0 0x90 0x90 0x90 0xe0
        0xf0 0x80 0xf0 0x80 0xf0
        0xf0 0x80 0xf0 0x80 0x80
    }

    proc lcpy {dest src offset} {
        upvar $dest d
        set until [expr {min([llength $d] - $offset, [llength $src])}]
        for {set i 0} {$i < $until} {incr i} {
            lset d [expr {$i + $offset}] [lindex $src $i]
        }
    }

    # Debug code. Remove later.
    if [info object isa object Cpu] {
        Cpu destroy
    }

    oo::class create Cpu {
        variable pc sp ri v ram vram stack ui thread

        constructor {u} {
            set sp 0
            set ri 0
            set v [lrepeat 0x10 0]
            set ram [concat $c8::FONT_SPRITES [lrepeat 0xfb0 0]]
            set vram [lrepeat 0x800 0]
            set stack [lrepeat 0x10 0]
            set ui $u
            set thread {}
        }

        method loadrom {rom} {
            c8::lcpy ram $rom 0x200
            set pc 0x200
        }

        method run {ms} {
            after cancel $thread
            my tick
            set thread [after $ms [list [self object] run $ms]]
        }

        method halt {} {
            after cancel $thread
            set thread {}
        }

        method fetch {} {
            lassign [lrange $ram $pc [expr {$pc + 1}]] h l
            incr pc 2
            return [expr {($h << 8) | $l}]
        }

        method tick {} {
            set op [my fetch]

            set n3 [expr {($op & 0xf000) >> 12}]
            set x [expr {($op & 0xf00) >> 8}]
            set y [expr {($op & 0xf0) >> 4}]
            set n0 [expr {$op & 0xf}]

            set nnn [expr {$op & 0xfff}]
            set kk [expr {$op & 0xff}]

            switch -regexp [list $n3 $x $y $n0] {
                {^0 0 14 0$}        { set vram [lrepeat 0x800 0]; $ui vrefresh vram }       ;# Cls
                {^0 0 14 14$}       { set pc [lindex $stack [incr sp -1]] }                 ;# Ret
                {^0 \d+ \d+ \d+$}   { puts stderr "UNIMPLEMENTED SYS OP: $nnn" }            ;# Sys
                {^1 \d+ \d+ \d+$}   { set pc $nnn }                                         ;# Jmp
                {^2 \d+ \d+ \d+$}   { lset stack $sp $pc; incr sp; set pc $nnn }            ;# Call
                {^3 \d+ \d+ \d+$}   { if {[lindex $v $x] == $kk} { incr pc 2 } }            ;# Se
                {^4 \d+ \d+ \d+$}   { if {[lindex $v $x] != $kk} { incr pc 2 } }            ;# Sne
                {^5 \d+ \d+ 0$}     { if {[lindex $v $x] == [lindex $v $y]} { incr pc 2 } } ;# Sre
                {^6 \d+ \d+ \d+$}   { lset v $x $kk }                                       ;# Ld
                {^7 \d+ \d+ \d+$}   { lset v $x [expr {([lindex $v $x] + $kk) % 0xff}] }    ;# Add
                {^8 \d+ \d+ 0$}     { lset v $x [lindex $v $y] }                            ;# Mov
                {^8 \d+ \d+ 1$}     { lset v $x [expr {[lindex $v $x] | [lindex $v $y]}] }  ;# Or
                {^8 \d+ \d+ 2$}     { lset v $x [expr {[lindex $v $x] & [lindex $v $y]}] }  ;# And
                {^8 \d+ \d+ 3$}     { lset v $x [expr {[lindex $v $x] ^ [lindex $v $y]}] }  ;# Xor
                {^8 \d+ \d+ 4$}     {
                        set s [expr {[lindex $v $x] + [lindex $v $y]}]
                        lset v $x [expr {$s % 0xff}]
                        lset v 0x0f [expr {$s > 0xff}]
                    }                                                                       ;# Addr
                {^8 \d+ \d+ 5$}     {
                        set s [expr {[lindex $v $x] - [lindex $v $y]}]
                        lset v $x [expr {$s % 0xff}]
                        lset v 0x0f [expr {$s >= 0}]
                    }                                                                       ;# Subr
                {^8 \d+ \d+ 6$}     {
                        lset v 0x0f [expr {[lindex $v $y] & 0x01}]
                        lset v $x [expr {[lindex $v $y] >> 1}]
                    }                                                                       ;# Shr
                {^8 \d+ \d+ 7$}     {
                        set s [expr {[lindex $v $y] - [lindex $v $x]}]
                        lset v $x [expr {$s % 0xff}]
                        lset v 0x0f [expr {$s >= 0}]
                    }                                                                       ;# Subnr
                {^8 \d+ \d+ 14$}    {
                        lset v 0x0f [expr {[lindex $v $y] & 0x80}]
                        lset v $x [expr {([lindex $v $y] << 1) & 0xff}]
                    }                                                                       ;# Shl
                {^9 \d+ \d+ 0$}     { if {[lindex $v $x] != [lindex $v $y]} { incr pc 2 } } ;# Srne
                {^10 \d+ \d+ \d+$}  { set ri $nnn }                                         ;# Ldi
                {^11 \d+ \d+ \d+$}  { set pc [expr {$nnn + [lindex $v 0]}] }                ;# Jmpi
                {^12 \d+ \d+ \d+$}  { lset v $x [expr {int(rand() * 0xff) & $kk|}] }        ;# Rand
                {^13 \d+ \d+ \d+$}  {
                        lset v 0x0f 0
                        for {set i 0} {$i < $n0} {incr i} {
                            set sbyte [lindex $ram [expr {$ri + $i}]]
                            set vert [expr {([lindex $v $y] + $i) % 32}]
                            for {set j 0} {$j < 8} {incr j} {
                                set horiz [expr {([lindex $v $x] + $j) % 64}]
                                set offset [expr {$vert * 64 + $horiz}]
                                set oval [lindex $vram $offset]
                                set nval [expr {($sbyte & (1 << (7 - $j))) != 0}]
                                if {$oval && $nval} {
                                    lset v 0x0f 1
                                }
                                lset vram $offset [expr {$oval ^ $nval}]
                            }
                        }
                        $ui vrefresh vram
                    }                                                                       ;# Draw - TODO
                {^14 \d+ 9 14$}     {}                                                      ;# Skp - TODO
                {^14 \d+ 10 1$}     {}                                                      ;# Sknp - TODO
                {^15 \d+ 0 7$}      {}                                                      ;# Movd - TODO
                {^15 \d+ 0 10$}     {}                                                      ;# Key - TODO
                {^15 \d+ 1 5$}      {}                                                      ;# Ldd - TODO
                {^15 \d+ 1 8$}      {}                                                      ;# Lds - TODO
                {^15 \d+ 1 14$}     { incr ri [lindex $v $x] }                              ;# Addi
                {^15 \d+ 2 9$}      { set ri [expr $x * 5] }                                ;# Ldspr
                {^15 \d+ 3 3$}      {
                        set vx [lindex $v $x]
                        set h [expr {$vx / 100}]
                        set t [expr {($vx - $h * 100) / 10}]
                        set o [expr {$vx - ($h * 100) - (t * 10)}]
                        c8::lcpy ram "$h $t $o" $ri
                    }                                                                       ;# Bcd
                {^15 \d+ 5 5$}      { c8::lcpy ram [lrange $v 0 $x] $ri }                   ;# Str
                {^15 \d+ 6 5$}      { c8::lcpy v [lrange $ram $ri [expr {$ri + $x}]] 0 }    ;# Read
                default             { puts stderr "BAD OPCODE: $op" }
            }

            # Debug code. Remove later.
            # puts [format "%04x" $op]
        }

        # Debug code. Remove later.
        method dumpv {} {
            puts "pc: $pc; v: $v"
        }
    }

    # Debug code. Remove later.
    if [info object isa object Ui] {
        Ui destroy
    }

    oo::class create Ui {
        variable vcache screen screenw screenh

        constructor {} {
            set vcache [lrepeat 0x800 0]
        }

        method create_window {width height} {
            set screen {.c}
            set screenw $width
            set screenh $height

            set x [expr {([winfo vrootwidth .] - $width) / 2}]
            set y [expr {([winfo vrootheight .] - $height) / 2}]

            wm title . tc8
            wm geometry . ${width}x${height}+$x+$y

            tk::canvas $screen -highlightthickness 0 -bg black
            grid $screen -sticky nwes -column 0 -row 0
            grid columnconfigure . 0 -weight 1
            grid rowconfigure . 0 -weight 1
        }

        method set_pixel {x y on} {
            set wx0 [expr {$x * ($screenw/64)}]
            set wy0 [expr {$y * ($screenh/32)}]
            set wx1 [expr {$wx0 + ($screenw/64)}]
            set wy1 [expr {$wy0 + ($screenh/32)}]
            set color [expr {$on ? "white" : "black"}]

            $screen create rect $wx0 $wy0 $wx1 $wy1 -fill $color -outline {}
        }
        unexport set_pixel

        method vrefresh {vram} {
            upvar $vram v
            set vsize [llength $v]
            for {set i 0} {$i < $vsize} {incr i} {
                if {[lindex $v $i] != [lindex $vcache $i]} {
                    lset vcache $i [lindex $v $i]
                    my set_pixel [expr {$i % 64}] [expr {$i / 64}] [lindex $v $i]
                }
            }
        }
    }

    proc readrom {fn} {
        fconfigure [set fp [open $fn r]] -translation binary
        binary scan [read $fp] c* data
        close $fp

        return [lmap x $data {expr {$x & 0xff}}]
    }
}
