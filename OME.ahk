CoordMode("Mouse", "Screen")

^l::Reload
^j::Main()

Main() {
    b1 := [137, 680]
    b2 := [788, 680]
    c1 := [67, 490] ; replace with your first extra click coordinate
    c2 := [600, 500] ; replace with your second extra click coordinate

    active := 1
    cycleStart := A_TickCount
    pauseMark := A_TickCount

    Focus(b1)

    Loop {
        SendBatch()

        ; random pause every minute
        if (A_TickCount - pauseMark >= 60000) {
            Sleep(Random(1000, 5000))
            pauseMark := A_TickCount
        }

        active := (active = 1) ? 2 : 1
        Focus(active = 1 ? b1 : b2)

        ; 2-minute cycle refresh with extra sequence
        if (A_TickCount - cycleStart >= 240000) {
            ; First refresh
            Refresh(b1)
            Refresh(b2)
            Sleep(5000) ; 5 seconds

            ; Second refresh
            Refresh(b1)
            Refresh(b2)
            Sleep(7000) ; 7 seconds

            ; Extra clicks
            Click(c1[1], c1[2])
            Sleep(1000)
            Click(c2[1], c2[2])
            Sleep(7000)

            ; reset cycle
            cycleStart := A_TickCount
            active := 1
            Focus(b1)
        }
    }
}

SendBatch() {
    Loop 3 {
        Send("^v")
        Send("{Enter}")

        Loop 3 {
            Send("{Esc}")
            Sleep(100)
        }
    }
}

Focus(pos) {
    Click(pos[1], pos[2])
    Sleep(200)
}

Refresh(pos) {
    Focus(pos)
    Send("^r")
    Sleep(100)
    Send("{Enter}")
    Sleep(500)
}