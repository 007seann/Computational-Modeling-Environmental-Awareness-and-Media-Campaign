globals
[
  years-to-simulate
  ;initial-num-packs
  initial-mean-pack-size
  carrying-capacity
  mean-birth-rate
  p-male
  ; disperser-meeting-rate
]


breed [dogs dog]
breed [packs pack]
breed [disperser-groups disperser-group]

dogs-own
[
  age  q
  sex
  status
]

disperser-groups-own
[
  sex
  natal-pack-ID
]

to setup
  clear-all
  set years-to-simulate 100
  ;set initial-num-packs 10
  set initial-mean-pack-size 5
  set carrying-capacity 60
  set mean-birth-rate 7.9
  set p-male 0.55
  ; set disperser-meeting-rate 1.0

  create-packs initial-num-packs
  [
    ; set a location and shape just for display
    setxy random-xcor random-ycor
    set shape "house"

    ; create the pack's dogs
    let num-dogs random-poisson initial-mean-pack-size
    hatch-dogs num-dogs
    [
      ; This block is in the context of a dog
      ; first, set display variables
      set heading random 360
      fd 1

      ; now assign dog state variables
      ifelse random-bernoulli 0.5
      [set sex "male"]
      [set sex "female"]

      set age random 7
      set-my-status ; a dog procedure that sets
                    ; social status from age

      ; create a link between the dog and its pack
      create-link-with myself

      ; nos
    ] ; end of hatch dogs

    ; now select the alpha dogs
    update-pack-alphas ; a pack procedure to give the
                       ; pack 2 alphas

  ] ; end of create-packs
  reset-ticks
end ; end of setup

to go

  tick
  if ticks > years-to-simulate [stop]

  ; First, age and status updates
  ask dogs
  [
    set age age + 1
    set-my-status
  ]

  ask packs [update-pack-alphas]

  ; Second, reproduction
  ask packs [reproduce]

  ; Third, dispersal
  ask packs [disperse]

  ; Fourth, mortality
  ask dogs [do-mortality]

  ; Fifth, mortality of collectives
  ask packs [do-pack-mortality]
  ask disperser-groups [if not any? link-neighbors [die]]

  ; Sixth, pack formation
  ask disperser-groups [do-pack-formation]

  ; Now some defensive programming
  ; All dogs should be linked to a pack or disperser group
  ; and all collectives should be linked to dogs
  ask turtles with [not any? link-neighbors]
  [
    error (word "There is a " breed " with no links; who number: " who)
  ]
  ask turtles with [any? link-neighbors with [breed = [breed] of myself]]
  [
    error (word breed " " who " is linked to another " breed)
  ]

  ; Finaly, produce output
  update-output

end

to-report random-bernoulli [probability-true]
  ; First do some defensive programming
  ; to make sure "probability-true" has a sensible value
  if probability-true < 0.0 or probability-true >  1.0
  [
    user-message (word
      "Warning in random-bernoulli: probability-true equals" probability-true)
  ]
  report random-float 1.0 < probability-true
end

; a dog procedure
to set-my-status
  ; Dispersers remain dispersers
  if status = "disperser" [stop]
  if age =  0 [set status "pup"]
  if age =  1 [set status "yearling"]
  if age >= 2 [set status "subordinate"]
end

; a pack procedure
to update-pack-alphas
  if not any? link-neighbors with [status = "alpha" and sex = "male"]
  [
    let my-male-subordinates link-neighbors with [status = "subordinate" and sex = "male"]
    update-alpha my-male-subordinates
  ]
  if not any? link-neighbors with [status = "alpha" and sex = "female"]
  [
    let my-female-subordinates link-neighbors with [status = "subordinate" and sex = "female"]
    update-alpha my-female-subordinates
  ]
  ; show (word count link-neighbors with [status = "alpha" and sex = "male"]   " alpha males")
  ; show (word count link-neighbors with [status = "alpha" and sex = "female"] " alpha females")
end

; an agenset procedure
to update-alpha [some-dogs]
  if any? some-dogs
  [
    ; show "Woof"
    ask one-of some-dogs [
      set status "alpha"
      ; show "WOOF"
    ]
  ]
end

; a dog procedure
to do-mortality
  ; 0.25 for yearlings
  ; 0.44 for dispersers
  ; 0.20 for subordinates
  ; 0.12 for pups
  if status = "yearling"    [ if random-bernoulli 0.25 [ die ] ]
  if status = "disperser"   [ if random-bernoulli 0.44 [ die ] ]
  if status = "subordinate" [ if random-bernoulli 0.20 [ die ] ]
  if status = "alpha"       [ if random-bernoulli 0.20 [ die ] ]
  if status = "pup"         [ if random-bernoulli 0.12 [ die ] ]
end

; a pack procedure
to do-pack-mortality
  if not any? link-neighbors [ die ]
  if all? link-neighbors [status = "pup" ]
  [
    ask link-neighbors [die]
    die
  ]
end

; a pack prodecure
to reproduce
  if (any? link-neighbors with [status = "alpha" and sex = "female"] and
      any? link-neighbors with [status = "alpha" and sex = "male"])
  [

    let N count dogs
    let P1 0.5
    let P2 0.1
    let X1 carrying-capacity / 2
    let X2 carrying-capacity
    let D ln(P1 / (1 - P1))
    let C ln(P2 / (1 - P2))
    let B (D - C)/(X1 - X2)
    let A (D - (B * X1))
    let Z exp(A + (B * N))
    let P Z / ( 1 + Z)
    ; show (word "Reproduce! N = " N " P = " P)
    if random-bernoulli P
      [
        ; show (word "Pack size before reproduction: " count link-neighbors)
        let num-dogs random-poisson mean-birth-rate
        ; show (word "Yap * " num-dogs)
        hatch-dogs num-dogs
        [
          ; This block is in the context of a dog
          ; first, set display variables
          set heading random 360
          fd 1

          ; now assign dog state variables
          ifelse random-bernoulli p-male
          [set sex "male"]
          [set sex "female"]

          set age 0
          set status "pup"

          ; create a link between the dog and its pack
          create-link-with myself
        ]
        show (word "Pack " who ": " num-dogs "births; size after reproduction: " count link-neighbors)
    ]
  ]
end

; a disperser-group procedure
to do-pack-formation
  ; Create agentset of other groups
  let other-groups other disperser-groups
  let num-other-groups count other-groups
  let num-groups-met random-poisson (disperser-meeting-rate * num-other-groups)
  show (word "Disperser group " who " originally from " natal-pack-ID " meets " num-groups-met " of " num-other-groups " other groups")
  repeat num-groups-met [
    let other-group one-of other-groups
    let source-group self
    if (([sex] of other-group) != sex and ([natal-pack-ID] of other-group != natal-pack-ID)) [
      show (word "Dispersing group " natal-pack-ID " with " (count link-neighbors)
        " dogs has met dispersing group " [natal-pack-ID] of other-group
        " with " (count [link-neighbors] of other-group) " dogs" )
      if random-bernoulli 0.64 [
        show (word "Pack merger")

        ; We will convert this dispersing pack into a pack
        hatch-packs 1
        [
          ; now in new pack context
          ; show (word "Pack size before creation: " count link-neighbors)

          ; set a location and shape just for display
          let xcor-new random-xcor
          let ycor-new random-ycor
          setxy xcor-new ycor-new
          set shape "house"

          ; create the pack's dogs
          let all-dogs (turtle-set [link-neighbors] of source-group [link-neighbors] of other-group)
          ; show all-dogs
          ask all-dogs
          [
            setxy xcor-new ycor-new
            ; This block is in the context of a dog
            ; first, set display variables
            set heading random 360
            fd 1

            set status "subordinate"
            ; create a link between the dog and its pack
            create-link-with myself

          ] ; end of pack creation

          ; now select the alpha dogs
          update-pack-alphas ; a pack procedure to give the
                             ; pack 2 alphas
          show (word "Pack after creation: " pack-stats)
        ]
        ; remove the dispersal groups
        ask other-group [die]
        die ; myself
      ]
    ]
  ]

end

; A pack helper procedure
to-report pack-stats
  report (word count link-neighbors with [status = "alpha" and sex = "male"]   " alpha males; "
          count link-neighbors with [status = "alpha" and sex = "female"] " alpha females; "
          count link-neighbors with [status = "subordinate"] " subordinates; "
          count link-neighbors with [status = "yearling"] " yearlings; "
          count link-neighbors with [status = "pup"] " pups")
end


to update-output
  ask packs [
    show (word "Pack " who ": " pack-stats)
  ]
end

; a pack procedure
to disperse
  ; First, identify the subordinates and stop if none
  let my-subordinates link-neighbors with [status = "subordinate"]
  if not any? my-subordinates [stop]

 ; Now check females
  if count my-subordinates with [sex = "female"]  = 1
  [
    if random-bernoulli 0.5
    [
      create-disperser-group-from
      my-subordinates with [sex = "female"]
    ]
  ]

  if count my-subordinates with [sex = "female"]  > 1
  [
    if random-bernoulli 0.5
    [
      create-disperser-group-from
      my-subordinates with [sex = "female"]
    ]
  ]

 ; Now check males
  if count my-subordinates with [sex = "male"]  = 1
  [
    if random-bernoulli 0.5
    [
      create-disperser-group-from
      my-subordinates with [sex = "male"]
    ]
  ]

  if count my-subordinates with [sex = "male"]  > 1
  [
    if random-bernoulli 0.5
    [
      create-disperser-group-from
      my-subordinates with [sex = "male"]
    ]
  ]
end ; to disperse

to create-disperser-group-from [some-dogs]
  ; a pack procedure
  ; "some-dogs" is an agentset of the dispersers

  ; First, create a disperser group and put the dogs in it
  hatch-disperser-groups 1
  [
    ; Set disperser group variables
    ; Here, "myself" is the pack creating the group
    set natal-pack-ID [who] of myself
    set sex [sex] of one-of some-dogs

    ; Display the group
    set shape "car"
    set heading random 360
    fd 2

    ; Now the disperser group sets the variables of the dispersing dogs
    ask some-dogs
    [
      ; first, un-link to the pack
      ask my-links [die]

      ; then create a link with the disperser group
      ; "myself" is now the disperser group
      create-link-with myself
      set status "disperser"
      set color green

      ; and display them on a radius
      ; from the disperser group
      move-to myself
      set heading [heading] of myself
      fd 1 + random-float 2
    ] ; end of ask some dogs
  ] ; end of hatch-disperser-groups
end ; to create-disperser-group-from
@#$#@#$#@
GRAPHICS-WINDOW
220
27
888
696
-1
-1
20.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
63
70
136
103
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
64
145
127
178
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
890
41
1090
191
Dogs
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count dogs"

PLOT
892
207
1092
357
Packs
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count packs"
"pen-2" 1.0 0 -2674135 true "" "plot count disperser-groups"

SLIDER
0
204
223
237
disperser-meeting-rate
disperser-meeting-rate
0
2
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
17
271
202
304
initial-num-packs
initial-num-packs
1
20
10.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Disperser group meeting rate" repetitions="400" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <exitCondition>count turtles = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="disperser-meeting-rate" first="0" step="0.5" last="2"/>
  </experiment>
  <experiment name="Disperser group meeting rate SA" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <exitCondition>count turtles = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="disperser-meeting-rate" first="0.5" step="0.05" last="1.5"/>
  </experiment>
  <experiment name="Disperser group meeting rate (2 param)" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <exitCondition>count turtles = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="disperser-meeting-rate" first="0" step="0.4" last="2"/>
    <steppedValueSet variable="initial-num-packs" first="2" step="2" last="20"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
