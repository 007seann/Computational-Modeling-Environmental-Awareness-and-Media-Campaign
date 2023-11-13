breed [humans human]   ;; Create people

humans-own [ eco_level r_vol sociability_range persuasion_level change_resistance_level ]
;; The person has an ecological awareness level "eco_level". This parameter will change according to the interaction with other people with a higher eco_level.
;; Its range will be from 1 to 10, where 1-3 the person is not interested in recycling, 4-7 is interested in recycling, however, they may or may not recycle (random between 0 and 1)
;; 8-10, people are environmentally conscious and always recycle.
;; The value of eco_level is associated with a persuasion_level and a change_resistance_level, both ranging from (0 to 100)%: if the person has an eco_level greater than that of another person
;; within his sociability_range, the ranges in his eco_level apply, if it is between 0 and 3, he has no intention of persuading others, if it is between 4 and 7, the person may be
;; encourage persuading another (random between 0 and 1), if it is between 8 and 10, you will always be willing to try to persuade others. If an agent persuasion process is initiated
;; towards another, the following procedure is followed: if the sender's persuasion_level is greater than the receiver's change_resistance_level, the receiver increases its eco_level by one unit.

;; Each person has an associated collection weight r_vol, which will be taken as weekly.
;; As long as the person does not have sufficient ecological awareness, this value is assumed as unrecovered recyclable.
;; which we will call recyclable_not_recovered_acum (mrec_nrec_ac)
;; On the other hand, we will accumulate the recovered recyclables in recyclable_recovered_cum (mrec_rec_ac)
;; Also, we will count the number of people in each eco_level range as:
;; - percentage_of_not-eco-friendly_people (nef_perc), percentage of people with average ecological behavior (efprom_perc) and percentage_of_eco-friendly_people (ef_perc)

;; People will move around the world, simulating the interaction they can have with different people they meet each week.
;; The movement will be given randomly between 1 and m_max per tick in any direction.

;; The number of people to create in each rank can be configured before starting the simulation.
;; Those in the first range will have between 1 and 3 in eco_level and a red color in scale (1: redder)
;; Analogously for the other two but in yellow and green.

;; The m_max is the maximum amount in units of movement that a person can have. It can also be configured from the beginning.
;; The value that results from a random between 1 and m_max will correspond to the movement_value of each agent.

;; The mean value and standard deviation to generate r_vol can also be entered on the screen. (vol_mean and vol_sd)

;; It serves to evaluate how the average level of environmental awareness in a population could evolve. On each tick an eco_level_av_pop (eco_level_pop) will be calculated

globals [
  nearby         ;; It is related to the sociability of each human (range - ability to interact with a greater or lesser number of close neighbors)
  mrec_nrec_ac   ;; quantification of the amount of non-recycled recyclable material (monitor)
  mrec_rec_ac    ;; quantification of the amount of recycled recyclable material (monitor)
  mat_no_recyc   ;; quantification of the amount of non-recyclable material
  nef_perc       ;; # of people in the first rank (monitor)
  efprom_perc    ;; # of people in the second rank (monitor)
  ef_perc        ;; # of people in the third rank (monitor)
  eco_level_pop  ;; average level of environmental awareness of the population. (monitor)

  avg_eco_level_pre_campaign ;;
  avg_eco_level_post_campaign ;;
  avg_persuasion_level_pre_campaign
  avg_persuasion_level_post_campaign
  avg_change_resistance_level_pre_campaign
  avg_change_resistance_level_post_campaign
]


to Setup
  clear-all
  ask patches [set pcolor 0]
  generate-population
  reset-ticks
end

to Begin

  ; This check is included in your main execution loop
  if ticks mod media_campaign_frequency = 0 [
    ifelse selected_campaign = "None" [
      ; Do nothing when 'None' is selected
    ] [
      ifelse selected_campaign = "All" [
        media-campaign
      ] [
        ifelse selected_campaign = "High" [
          media-campaign-high
        ] [
          ifelse selected_campaign = "Medium" [
            media-campaign-medium
          ] [
            media-campaign-low
          ]
        ]
      ]
    ]
  ]

   ask humans [
     if (change_sociability_behavior?) [set sociability_range 1 + random sociability_max ]
     let a sociability_range
     neigborhood-type a
     let eco_level_emisor eco_level ;eco_level_emitter
     let persuasion_level_emisor eco_level ;persuasion_level_emitter
     ask patches at-points nearby [set pcolor [9] of myself]
       ask humans at-points nearby [
       let temp eco_level + (1 * (learning_rate / 100) )
       if eco_level_emisor > eco_level [
         if  eco_level_emisor >= 8 [
           set pcolor 96   ;; Start of persuasion attempt
           if (persuasion_level_emisor > change_resistance_level) [
            ifelse temp < 10 [set eco_level temp][set eco_level 10]
             set pcolor 0]
         ]
         if  (eco_level_emisor >= 3) And (eco_level_emisor < 8) [
           set pcolor 96
           if (persuasion_level_emisor > change_resistance_level) And (random 2 = 1) [
             set eco_level temp
             set pcolor 0]
         ]
       ]
     ]

     ifelse (show_eco_level?)
     [let lab precision eco_level 2 set label (lab) ]
     [set label "" ]
        ask patches at-points nearby [set pcolor [0] of myself]
        let temp 0
    rt random 360 fd 1 + random desplazamiento_max

    actualizar_color eco_level
       ]
   set mrec_nrec_ac 0
   set mrec_rec_ac 0
   set mat_no_recyc 0
   set nef_perc 0
   set efprom_perc 0
   set ef_perc 0
   set eco_level_pop 0
   actualizar_variables
   tick
  if (ticks = 365) [ stop ]
end
to actualizar_color [level]
  if level < 3 [set color 15]
  if level >= 3 And level < 8 [set color 46]
  if level >= 8 [set color 64]

end

to actualizar_variables
  ask humans [
    if eco_level < 3 [
      set mrec_nrec_ac mrec_nrec_ac + r_vol * ( (recyc_perc_g1 / 100) )
      set mat_no_recyc mat_no_recyc + r_vol * ( 1 - (recyc_perc_g1 / 100) )
      set nef_perc nef_perc + 1
    ]
    if (eco_level >= 3) And (eco_level < 8)
    [ set efprom_perc efprom_perc + 1
      ifelse (random 2 = 1)  ; If you decide to recycle, its volume is classified as well disposed, otherwise it is included as incorrectly disposed.
      [set mrec_rec_ac mrec_rec_ac + r_vol * ( (recyc_perc_g2 / 100) ) set mat_no_recyc mat_no_recyc + r_vol * ( 1 - (recyc_perc_g2 / 100) )]
      [set mrec_nrec_ac mrec_nrec_ac + r_vol * ( (recyc_perc_g2 / 100) ) set mat_no_recyc mat_no_recyc + r_vol  * ( 1 - (recyc_perc_g2 / 100) )]
    ]
    if eco_level >= 8 [
      set ef_perc ef_perc + 1
      set mrec_rec_ac mrec_rec_ac + r_vol * ( (recyc_perc_g3 / 100) ) set mat_no_recyc mat_no_recyc + r_vol * ( 1 - (recyc_perc_g3 / 100) )]
    set eco_level_pop eco_level_pop + eco_level
]
  set eco_level_pop eco_level_pop / (nef_perc + efprom_perc + ef_perc)
end

;add in high, medium, low camogain with a slection to start
; create the probability, with high having higher chance of beign affected.
; high = 80, med = 50, low =20 chance of being.
to media-campaign
  ; Only execute this procedure every 'media_campaign_frequency' ticks
  if ticks mod media_campaign_frequency = 0 [
    calculate-averages "pre"
    ; Randomly select 'x' agents from the population, where 'x' is the campaign size
    let selected-agents n-of campaign_size turtles

    ; Ask each selected agent to evaluate the media campaign effect
    ask selected-agents [
      ifelse eco_level >= 8 [
        ; 80% chance to increase persuasiveness
        if random-float 1 < 0.8 [
          set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
        ]
      ] [
        ifelse eco_level >= 4 [
          ; 50% chance for change
          if random-float 1 < 0.5 [
            ; Randomly decide to increase or decrease persuasiveness
            ifelse random-float 1 < 0.5 [
              set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
            ] [
              set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
            ]
          ]
        ] [
          ; 20% chance to decrease RTC for low eco level
          if random-float 1 < 0.2 [
            set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
          ]
        ]
      ]
    ]
    calculate-averages "post"
    update-graph
  ]
end


to calculate-averages [time]
  if time = "pre" [
    set avg_eco_level_pre_campaign mean [eco_level] of humans
    ;; set avg_persuasion_level_pre_campaign mean [persuasion_level] of humans
    ;; set avg_change_resistance_level_pre_campaign mean [change_resistance_level] of humans
  ]
  if time = "post" [
    set avg_eco_level_post_campaign mean [eco_level] of humans
    ;; set avg_persuasion_level_post_campaign mean [persuasion_level] of humans
    ;; set avg_change_resistance_level_post_campaign mean [change_resistance_level] of humans
]
end

to update-graph
  set-current-plot "Media Campaign Impact"
  set-current-plot-pen "Avg Eco Level Pre"
  plot avg_eco_level_pre_campaign
  set-current-plot-pen "Avg Eco Level Post"
  plot avg_eco_level_post_campaign
  ; Repeat for other variables
end


to media-campaign-high
  if ticks mod media_campaign_frequency = 0 [
    calculate-averages "pre"
    let selected-agents n-of campaign_size turtles with [eco_level >= 8]
    ask selected-agents [
      if random-float 1 < 0.8 [
        set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
      ]
    ]
    calculate-averages "post"
    update-graph
  ]
end


to media-campaign-medium
  if ticks mod media_campaign_frequency = 0 [
    calculate-averages "pre"
    let selected-agents n-of campaign_size turtles with [eco_level >= 4 and eco_level < 8]
    ask selected-agents [
      if random-float 1 < 0.5 [
        ifelse random-float 1 < 0.5 [
          set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
        ] [
          set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
        ]
      ]
    ]
    calculate-averages "post"
    update-graph
  ]
end


to media-campaign-low
  if ticks mod media_campaign_frequency = 0 [
    calculate-averages "pre"
    let selected-agents n-of campaign_size turtles with [eco_level < 4]
    ask selected-agents [
      if random-float 1 < 0.2 [
        set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
      ]
    ]
    calculate-averages "post"
    update-graph
  ]
end





to generate-population
  ;; generation of humans of the first group: people who are not friendly to the environment (they do not recycle)
  set-default-shape humans "person service"
  create-humans humanos_grupo1 [
; set color 15 ; give red color to the agents of the first group
    set eco_level random 3 ; from 0 to 2
    set r_vol random-normal media_res desv_est_res
    set sociability_range 1 + random sociability_max    ;; the sociability range will be from 1 to 10
    set persuasion_level random-float 1
    set change_resistance_level random-float 1
  ]
  ask humans [
    set size 1.2  ;; modify size
    setxy random-pxcor random-pycor
    ifelse (show_eco_level?)
    [set label (eco_level) ]
    [set label "" ]
  ]

  ;; generation of humans of the second group: intermediate people in terms of environmental awareness (sometimes they recycle)
  set-default-shape humans "person service"
  create-humans humanos_grupo2 [
; set color 46 ; give red color to the agents of the first group
    set eco_level 3 + random 5 ;from 3 to 7
    set r_vol random-normal media_res desv_est_res
    set sociability_range 1 + random sociability_max    ;; the sociability range will be from 1 to 10
    set persuasion_level random-float 1
    set change_resistance_level random-float 1
  ]
  ask humans [
    set size 10  ;; modify size
    setxy random-pxcor random-pycor
    ifelse (show_eco_level?)
    [set label (eco_level) ]
    [set label "" ]
  ]

 ;; generation of humans of the third group: people with environmental awareness (they always recycle)
  set-default-shape humans "person service"
  create-humans humanos_grupo3 [
; set color 64 ; give red color to the agents of the first group
    set eco_level 8 + random 3 ;from 8 to 10
    set r_vol random-normal media_res desv_est_res
    set sociability_range 1 + random sociability_max    ;; the sociability range will be from 1 to 10
    set persuasion_level random-float 1
    set change_resistance_level random-float 1
  ]
  ask humans [
    set size 1.5  ;; modify size
    setxy random-pxcor random-pycor
    actualizar_color eco_level
    ifelse (show_eco_level?)
    [set label (eco_level) ]
    [set label "" ]
  ]
end
to neigborhood-type[radio]
  ifelse sociability_range_type = "Von Neumann"
  [set nearby von-neumann-offsets radio ]
  [set nearby moore-offsets radio]
end
to-report von-neumann-offsets [ n ]
  let result [list pxcor pycor] of patches with [abs pxcor + abs pycor <= n ]
  report remove [0 0] result
end
to-report moore-offsets [ n ]
  let result [list pxcor pycor] of patches with [abs pxcor <= n and abs pycor <= n ]
  report remove [0 0] result
end
@#$#@#$#@
GRAPHICS-WINDOW
621
15
1213
608
-1
-1
14.244
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

SLIDER
231
89
380
122
humanos_grupo1
humanos_grupo1
1
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
207
147
355
180
humanos_grupo2
humanos_grupo2
1
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
211
198
367
231
humanos_grupo3
humanos_grupo3
1
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
247
282
374
315
desplazamiento_max
desplazamiento_max
1
20
4.0
1
1
NIL
HORIZONTAL

INPUTBOX
441
318
533
378
media_res
0.95
1
0
Number

INPUTBOX
442
390
533
450
desv_est_res
0.3
1
0
Number

TEXTBOX
117
289
247
328
Maximum allowed displacement of people per unit of time
8
0.0
1

BUTTON
299
589
410
622
Begin
Begin
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
186
589
289
622
Initialise
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
456
544
591
577
show_eco_level?
show_eco_level?
0
1
-1000

CHOOSER
247
401
376
446
sociability_range_type
sociability_range_type
"Moore" "Von Neumann"
1

SLIDER
89
450
190
483
sociability_max
sociability_max
1
10
4.0
1
1
NIL
HORIZONTAL

MONITOR
1473
13
1586
58
RWSI
mrec_nrec_ac
4
1
11

PLOT
1178
14
1464
177
Waste  (Kg) vs Time
Time
Kg
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"RWSI" 1.0 0 -2674135 true "" "plot mrec_nrec_ac"
"RWSC" 1.0 0 -13840069 true "" "plot mrec_rec_ac"
"NW" 1.0 0 -12895429 true "" "plot mat_no_recyc"
"Total" 1.0 0 -1513240 true "" "plot (mrec_nrec_ac + mrec_rec_ac + mat_no_recyc)"

MONITOR
1473
66
1586
111
RWSC
mrec_rec_ac
4
1
11

MONITOR
1485
184
1580
229
# G1
nef_perc
17
1
11

MONITOR
1486
235
1581
280
# G2
efprom_perc
17
1
11

MONITOR
1487
291
1582
336
# G3
ef_perc
17
1
11

MONITOR
1277
357
1510
402
Average eco-level
eco_level_pop
8
1
11

PLOT
1177
191
1453
341
Population (#) vs Time
Time
Population (#)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"G1" 1.0 0 -2674135 true "" "plot nef_perc"
"G2" 1.0 0 -1184463 true "" "plot efprom_perc"
"G3" 1.0 0 -13840069 true "" "plot ef_perc"
"Total" 1.0 0 -3026479 true "" "plot nef_perc + efprom_perc + ef_perc"

TEXTBOX
445
271
542
315
Average and deviation of waste (kg/inhabitant/day)
9
0.0
1

TEXTBOX
117
92
230
147
People with low or no environmental awareness(No recycle)
8
0.0
1

TEXTBOX
98
148
219
200
People with a medium environmental awareness\n(Sometimes recycle)
8
0.0
1

TEXTBOX
104
201
225
253
People with a high level of encvironmental awareness\n(Always recycle)
8
0.0
1

TEXTBOX
424
29
545
68
Percentage of potentially recyclable waste
10
0.0
1

SLIDER
419
84
569
117
recyc_perc_g1
recyc_perc_g1
0
100
20.0
1
1
%
HORIZONTAL

SLIDER
418
146
565
179
recyc_perc_g2
recyc_perc_g2
0
100
30.0
1
1
%
HORIZONTAL

SLIDER
419
204
565
237
recyc_perc_g3
recyc_perc_g3
0
100
50.0
1
1
%
HORIZONTAL

MONITOR
1475
118
1588
163
NW
mat_no_recyc
4
1
11

PLOT
1181
411
1582
531
Average eco-level
Time
Eco_level
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot eco_level_pop"

SWITCH
453
493
543
526
change_sociability_behavior?
change_sociability_behavior?
1
1
-1000

TEXTBOX
331
493
441
537
Allow change of maximum sociability range during execution
9
0.0
1

SLIDER
247
341
373
374
learning_rate
learning_rate
0
100
3.0
1
1
%
HORIZONTAL

TEXTBOX
37
355
151
381
Individual learning rate
10
0.0
1

TEXTBOX
33
416
158
447
Type of sociability range
10
0.0
1

TEXTBOX
29
446
103
485
Maximum range of sociability
10
0.0
1

SLIDER
199
15
387
48
media_campaign_frequency
media_campaign_frequency
0
365
31.0
1
1
NIL
HORIZONTAL

SLIDER
200
51
365
84
campaign_size
campaign_size
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
211
243
372
276
media_campaign_strength
media_campaign_strength
0
1
0.05
0.05
1
NIL
HORIZONTAL

CHOOSER
178
528
320
573
selected_campaign
selected_campaign
"High" "Medium" "Low" "All" "None"
1

TEXTBOX
54
245
204
275
Strength of the media campaign, this is how much is added/subtracted from persuaiveness/resistance
8
0.0
1

TEXTBOX
19
541
169
561
\"All\" is random for everyone, \"High\" is high eco level people, so on.
8
0.0
1

TEXTBOX
35
27
185
47
How often campaign occurs, e.g 30 is every month\n
8
0.0
1

TEXTBOX
51
55
201
85
Size of the campaign. REMEBER AND MAKE THIS SMALLER THAN THE SIZE OF THE GROUP WE ARE TARGETING
8
0.0
1

PLOT
807
509
1939
1058
Media Campaign Impact
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
"Avg Eco Level Pre" 1.0 0 -13791810 true "" "plot avg_eco_level_pre_campaign"
"default" 1.0 0 -16777216 true "" "plot eco_level_pop"
"Avg Eco Level Post" 1.0 0 -2674135 true "" "plot avg_eco_level_post_campaign"

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

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

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
  <experiment name="Baseline" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="campaign_size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="31"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-High" repetitions="1" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;High&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="campaign_size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="31"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-Medium" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;Medium&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="campaign_size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="31"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-Low" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;Low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="campaign_size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="31"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-All" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;All&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="campaign_size">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="31"/>
    </enumeratedValueSet>
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
