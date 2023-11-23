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
  mrec_nrec_ac   ;; quantification of the amount of non-recycled recyclable material (monitor) - mrec_nrec_ac: monitor recycled not recycled accurately counted
  mrec_rec_ac    ;; quantification of the amount of recycled recyclable material (monitor) - mrec_rec_ac: monitor recycled recycled accuractely counted
  mat_no_recyc   ;; quantification of the amount of non-recyclable material - mat_no_recyc: material not recyclable
  nef_perc       ;; # of people in the first rank (monitor) - nef_prec: not eco-friendly percentage (low group)
  efprom_perc    ;; # of people in the second rank (monitor) - efprom_perc: eco-friendely promedio(average) percentage (medium group)
  ef_perc        ;; # of people in the third rank (monitor) - ef_prec: eco-friendly percentage (high group)
  eco_level_pop  ;; average level of environmental awareness of the population. (monitor) - eco_level_pop: ecological level of the population
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
     let persuasion_level_emisor eco_level ;persuation_level_emitter
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

    ask turtles [
      ifelse eco_level >= 8 [
        ; 80% chance to increase persuasiveness
        if random-float 1 < 0.8 [
          set eco_level min list 10 (eco_level + 1)
          set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
        ]
      ] [
        ifelse eco_level >= 4 [
          ; 50% chance for change
          if random-float 1 < 0.5 [
            ; Randomly decide to increase or decrease persuasiveness
            ifelse random-float 1 < 0.5 [
              set eco_level min list 10 (eco_level + 1)
              set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
            ] [
              set eco_level min list 10 (eco_level + 1)
              set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
            ]
          ]
        ] [
          ; 20% chance to decrease RTC for low eco level
          if random-float 1 < 0.2 [
            set eco_level min list 10 (eco_level + 1)
            set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
          ]
        ]
      ]
    ]
  ]
end

to media-campaign-high
  if ticks mod media_campaign_frequency = 0 [
    ask turtles with [eco_level >= 8] [
      if random-float 1 < 0.8 [
        set eco_level min list 10 (eco_level + 1)
        set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
      ]
    ]
  ]
end



to media-campaign-medium
  if ticks mod media_campaign_frequency = 0 [
    ask turtles with [eco_level >= 4 and eco_level < 8] [
      if random-float 1 < 0.3 [ ; 40% chance for medium eco-level agents
        ifelse random-float 1 < 0.5 [ ; Further 50% chance of one of the two outcomes
          ; First Outcome: Increase eco_level and persuasion_level
          set eco_level min list 10 (eco_level + 1)
          set persuasion_level min list 1 (persuasion_level + media_campaign_strength)
        ] [
          ; Second Outcome: Increase eco_level and decrease change_resistance_level
          set eco_level min list 10 (eco_level + 1)
          set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
        ]
      ]
    ]
  ]
end




to media-campaign-low
  if ticks mod media_campaign_frequency = 0 [
    ask turtles with [eco_level < 4] [
      if random-float 1 < 0.2 [
        set eco_level min list 10 (eco_level + 1)
        set change_resistance_level max list 0 (change_resistance_level - media_campaign_strength)
      ]
    ]
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
    set size 0.12  ;; modify size
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
    set size 1  ;; modify size
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
    set size 0.15  ;; modify size
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
620
15
1212
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
10000
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
10000
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
10000
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
10
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
7.0
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
1.0
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
0

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
How often campaign occurs, e.g 31 is every month\n
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

@#$#@#$#@
# ODD Template
This ODD template is the modified ODD to explore the impacts of media campagins on population eco-level in a developing country of the original paper, Agent-based Model for Environmental Awareness and Extended Producer Responsibility in Developing Countries (Galarcio, Ramírez, Maya Duque, & Ceballos, 2020).

The relevant figures or tables in this template can be found on the original paper. 

## A. Overview

### 1) Purpose
With this model, we want to understand how environmental awareness level, consumption habits, and individual social skills  influence the average eco-level and waste separation behaviours at the source of a population. The latter is measured in terms of the amount of waste properly separated. This model aims at supporting decision makers and authorities in charge of design policies of extended producer responsibility in different packaging classes, so that, according to the specific characteristics of a population, they could generate and project estimates on the average environmental awareness level and the amount of recycled material.  This would allow them to evaluate the relevance and viability of the percentage thresholds that they raise in terms of recovered material and the deadlines that are foreseen in planning governmental policies.

### 2) Entities, state variables and scales
The model consists of a single human agent that represents an individual in the population. Each human has the following characteristics: environmental awareness level (eco-level), amount of waste generated, sociability radius, persuasiveness, and level of resistance to change. All variables are endogenous since none are affected by external alterations. Global variables are included such as the amount of recoverable waste separated in a  correct way  (RWSC), the amount of recoverable waste separated incorrectly (RWSI) and the amount of non-recoverable waste (NW)  in kilograms.  In addition,  there are variables such as the number of people within the range of low (NPLe), medium (NPMe) or high (NPHe) eco-level. Also, each group has a percentage of potentially recyclable waste according to its consumption habits. Finally, we have a learning rate to improve the eco-level of individuals, and the average environmental awareness level of the population (average eco-level). Table 1 shows the range of each variable. For its part, space implicitly represents a closed place where humans frequent and interact. It could represent, for example, the campus of a  university or a delimited geographical area (Figure 1(a)). Space allows one or another type of neighbourhood at the same time:  according to  Moore or von Neumann neighbours (Figure 1(b) and (c)).


Fig. 1.  (a) Space in which simulated events occur, (b) Von Neumann neighbours with radius = 3, and (c) Moore's neighbours with radius = 2.
The sociability range represents how sociable the individual is and gives him the ability to interact with more or fewer neighbours. Finally, each tick represents a unit of time in which humans interact between them within their radius of sociability and perform a displacement. For this model, a unit of time represents a day.


### 3) Process overview and scheduling

After the model initialization, each human checks its neighbourhood within its sociability radius according to the type of neighbourhood defined for the simulation. If the agent meets another human within its neighbourhood, it will act according to its characteristics. 
That is, if the neighbour’s eco-level is greater than the agent's eco-level, it proceeds to check the next neighbour. If the neighbour’s eco-level is lower than the agent's eco-level and the agent is part of the low group (eco-level < 3), the agent will do nothing. If the neighbour’s eco-level is less than the agent eco- level and the agent is part of the middle group (3 ≤ eco-level <8), a binary random number is generated, if the number is equal to 1,  a persuasion process is initiated that consists in comparing the persuasiveness of the human with the level of resistance to change of its neighbour, if the human persuasiveness is greater than the level of the neighbour, the eco- level of the neighbour will be increased according to the learning rate that has been set for simulation, otherwise,  no action is taken. Finally, if the human is part of the high-level eco-group (8 ≤ eco-level ≤ 10), it will always start a persuasion process and try to increase the eco-level of its neighbours and its success will depend on human persuasiveness. 

Once the agent interacts with all its neighbours,  an integer random number is generated between 1 and the maximum displacement value defined and the agent moves in any direction according to the value generated.  If a  human changes from one group to another (NPLe, NPMe and NPHe), its consumption habits change. Ideally, it will increase its consumption of products with potentially recoverable waste and will decrease proportionally the consumption of products that are not environmentally friendly. In the model, this is represented as a modification in the percentage of potentially recoverable waste that the human contributes to the total waste generated in the system. 
After performing this procedure for each agent, the following criteria are considered: If the human is part of the NPLe,  it is assumed that it does not separate. If the human is part of the NPMe, it may or may not separate correctly. Finally, if the agent is part of the NPHe, it will always separate correctly. From the above, the following global variables are updated: RWSC, RWSI, NW, and average eco-level for the population. The above procedure is shown in Figure 2.


## B. Design concepts 

### 1) Theoretical and empirical background 
The model arises in response to developing tools to test the policies designed for extended liability schemes  [6], [11], [12], [21], taking into account that environmental awareness cannot be taken for granted in development countries [14], and that it is possible to analyse the behaviours of heterogeneous and autonomous populations through ABS  [16],  [22], [23]. In addition, successful models of ABS have been developed that involve environmental awareness and social behaviours [24]. 

### 2) Learning 
Humans are increasing their eco-level,  so it is possible to affirm that there is learning,  which is incorporated into the decision process through the level of resistance to change (an individual can refuse to increase their eco-level).  It is not implemented, but collective learning is measured.

Fig. 2.  Simplified process description.

### 3) Individual sensing 
In general, humans perceive their eco-level, their belonging to one group or another to make decisions, and neighbours within their sociability radius.  When an agent tries to persuade another, it perceives the eco-level and the resistance to change, while the other agent perceives his persuasiveness. The spatial detection scale is local.  In addition,  the mechanisms for obtaining information are implicitly modelled if the agents know the values of these variables. The costs of cognition or information gathering are not explicitly included. 

### 4) Individual prediction 
In this model, each human must know how many neighbours are within their sociability radius and predict the eco-level of each of their neighbours to determine if they are susceptible to being influenced. According to the group to which they belong, the human may adopt different positions: not persuade - not separate waste, persuade and separate occasionally, or always persuade and separate. It could be said that knowing the change resistance level of a neighbour, they can predict a failed attempt at persuasion, and knowing the eco-level of their neighbour, they can predict an unnecessary or potentially successful persuasion. 

### 5) Interaction 

The interactions between humans would occur directly, depending on the sociability radius, the type of neighbourhood, and the position of each agent in space. The communication between the agents consists of a process of persuasion - resistance to change, which refers to the power of conviction that a human has and that they use to try to persuade, confronted with the resistance that another human imposes to change its way of thinking in terms of environmental awareness, that is, its eco-level, and, gradually, its consumption habits. This communication, as already mentioned, is represented by comparing the variable persuasiveness with the level of resistance to change.
.
### 6) Collectives 
Three groups can affect and be affected by the agents. Agents with a low environmental awareness are represented with the colour red, have an eco-level between 0 and 3 (not including 3), and are characterized by having little ecological consumption habits, in which the percentage of potentially recoverable waste is necessarily low, and this small percentage is not separated, so it becomes part of the recoverable material not separated or incorrectly separated. In consequence, these humans do not try to persuade others to increase their environmental awareness. Agents with a medium environmental awareness are shown in yellow, their eco-level is between 3 and 8 (not including 8), they have moderately ecological consumption habits, then their percentage of potentially recoverable waste is strictly higher than the agents of the first group. The behaviour of those agents is variable: in some cases, they are willing to persuade others to increase their ecological awareness, however, they may also decide to assume a passive stance and not take any action. For classifying the recoverable material, they follow the same pattern of behaviour, so they contribute both to the recyclable material not separated or incorrectly separated, as well as to the recyclable material properly separated. This way of proceeding is represented by generating a value that can be 0 or 1, with 1 being the value that indicates a decision in favour of the environment. Finally, we have agents that have high environmental awareness, are represented with the colour green, their eco-level is between 8 and 10, and have highly ecological consumption habits, so the percentage of potentially recoverable waste derived from the products consumed is necessarily high. They always appropriately perform the separation process, so it contributes to the recyclable material being properly separated.
It is important to mention that there is a part of the waste that is not recoverable, therefore, all humans contribute to the recyclable material in a percentage of the total of their generated waste, which would be 1 minus the percentage of potentially recoverable waste applied for each collective. The number of individuals belonging to each group is defined by the researcher on a preliminary basis and changes based on the interactions between the agents.

### 7) Heterogeneity 
As already mentioned, the set of human agents is heterogeneous, both in the value of their state variables and in decision-making. This difference is reflected in the decisions that each agent can make according to their degree of environmental awareness.


### 8) Stochasticity 
The model includes random aspects, both in the decision-making of the agents (binary random) and in the initialization of the state variables and the model in general. The initialization process will be detailed later. 

### 9) Observation 
The data collected from the simulation includes RWSC, RWSI, and NW generated by the population. This information is extracted after a tick, which represents a day in our model. Figure 3 (a) shows an example of the model outputs for a 10-day simulation. Another important fact is the number of people that make up each group, which allows us to identify how the proportions change as their eco-level changes, and how it is reflected in waste separation behaviors at the source. How an observer perceives that information is presented in Figure 3 (b).

Fig. 3. (a) Discriminated amount of waste from the population (Kg), and (b) Evolution of the number of people per group.

Finally, we have the average eco-level, which is calculated as the average of the eco-levels of all humans. This data is key to our analysis, as it allows us to see how environmental awareness evolves. The key results and the characteristics of the model outputs are emerging, taking into account that, although the average ecological level is expected to grow gradually, it is difficult to know in advance at which moment in time the population will reach a mature ecological behaviour, how the population composition changes according to the three defined groups, and what approximate amount of recyclable waste properly separated could be expected at any given moment in time according to the environmental awareness of the population.

## C. Submodel
In this experiment, we additionally want to see the influences of media campaigns on an agent’s environmental awareness within developing countries. To do that, we added media campaigns as an extraneous variable to affect the agent’s environmental awareness. The degree of alteration of an agent’s environmental awareness corresponds to each agent’s eco level, and its eco level can increase, remain, or decrease due to the media campaign and resistance to change state variable of an agent. If a media campaign educates an agent with a high eco level, their persuasiveness can increase. If the campaign educates one at mid eco-level, it randomly affects their persuasiveness. In this experiment, the probability to increase or decrease their persuasiveness is 0.5. If the media works on an agent with a low eco level, it decreases resistance to change. In our experiment, we selected scenario 3 of the reference paper as our baseline BS. This scenario 3 represents a realistic situation based on empirical experiments in the paper. Thus, this is the baseline without media campaigning. Our following experiment scenario is divided into 4 scenarios. First, a media campaign randomly targets three eco-level groups; low, medium, and high. The second scenario targets only an agent with a low eco level. Third, it targets only a medium eco-level group. Fourth, it targets only a high eco-level group. Afterwards, we compared these scenarios to see the influences of media campaigns on environmental awareness. 

Furthermore, we also parameterised the strength of the media campaign and its exposure frequency to an agent to diversify our experiment. The strength range is 0 to 1. Frequency is set to 30, which means the media campaign exposes an agent once a month. The 3% learning rate is the same as used in the paper to control the purpose of the experiment. To explore more experiments to discover the impact of media campaigns, we could change the values of these parameters. 

## D. Details 
The model was implemented in the NetLogo software, and the code can be accessed through the authors of this work. Concerning the initialization, its initial state will depend on the population type, allowing the generation of the value of the waste produced by each human in (kg/hab./day) from a normal distribution with a given mean and deviation. For this value, we have used a mean of 0.95 and a deviation of 0.1. The average value has been obtained from the literature for 2012 [3]; however, the deviation has been empirically set.

Also, it is possible to set the number of individuals to be generated and the percentage of potentially recyclable waste (consumption habits) for each group. The number of individuals could be defined according to a proportion of a real population; however, all these values have been empirically defined, respecting the assumption that, at the beginning, NPLe > NPMe > NPHe for quantity, and rwNPLe < rwNPMe < rwNPHe for the percentage of potentially recyclable waste that would be determined by consumption habits.

In addition, the maximum displacement allowed for all humans can be defined per unit of time, which is generated from a random integer between 1 and this maximum value for everyone in each tick. This value can be modified during the simulation and has been empirically set. Another key value that can be established at the beginning and modified during the simulation is the learning rate of individuals. This rate helps us adjust the model to consistent results from the point of view of learning - time.

Finally, we have values related to the social aspect. The sociability radius, which could be characteristic of everyone from beginning to end or be dynamic in the simulation, in this case, has been set as a characteristic of everyone. For its part, the Moore/Von Neumann type of neighbourhood can also be static or modified during the simulation. To initialize and execute the model, there are interface controls for the following variables: waste generated (mean and standard deviation), sociability radius, NPLe, rwNPLe, NPMe, rwNPMe, NPHe, rwNPHe, learning rate, maximum offset, and type of neighbourhood.
Concerning the sub-models, these have been detailed throughout this work. Considering that the model and all sub-models were designed in the absence of research associated the factors present in this work, there are no reference values for most of the model parameters; however, the ranges defined for the state variables are available in Table 1.

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
  <experiment name="stevenexperiment" repetitions="3" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <timeLimit steps="365"/>
    <metric>mrec_nrec_ac</metric>
    <metric>mrec_rec_ac</metric>
    <metric>mat_no_recyc</metric>
    <metric>nef_perc</metric>
    <metric>efprom_perc</metric>
    <metric>ef_perc</metric>
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
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
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
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>Begin</go>
    <metric>mrec_nrec_ac</metric>
    <metric>mrec_rec_ac</metric>
    <metric>mat_no_recyc</metric>
    <metric>nef_perc</metric>
    <metric>efprom_perc</metric>
    <metric>ef_perc</metric>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
      <value value="&quot;Moore&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="3"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.1"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4-7days-High_by_sean" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <timeLimit steps="1250"/>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;High&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4-7days-Medium_by_sean" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <timeLimit steps="1250"/>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;Medium&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4-7days-Low_by_sean" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <timeLimit steps="1250"/>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;Low&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4-7days-All_by_sean" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <timeLimit steps="1250"/>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;All&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4-7days-None_by_sean" repetitions="10" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Begin</go>
    <timeLimit steps="1250"/>
    <metric>eco_level_pop</metric>
    <enumeratedValueSet variable="humanos_grupo1">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo2">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="humanos_grupo3">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g1">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g2">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recyc_perc_g3">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning_rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_range_type">
      <value value="&quot;Von Neumann&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sociability_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_eco_level?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desplazamiento_max">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change_sociability_behavior?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_res">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desv_est_res">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_frequency">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="media_campaign_strength">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selected_campaign">
      <value value="&quot;None&quot;"/>
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
