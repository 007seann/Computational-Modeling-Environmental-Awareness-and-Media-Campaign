breed [humans human]   ;; Crea personas

humans-own [ eco_level r_vol sociability_range persuasion_level change_resistance_level ]
;; La persona tiene un nivel de conciencia ecológica "eco_level". Este parámetro irá cambiando de acuerdo a la interacción entre personas con eco_level más alto.
;; Su rango será de 1 a 10, donde 1-3 la persona no se interesa por reciclaje, 4-7, se interesa por el reciclaje, sin embargo, puede o no reciclar (aleatorio entre 0 y 1)
;; 8-10, las personas tienen concienciencia ambiental y siempre reciclan.
;; Al valor de eco_level se asocia un persuasion_level y a un change_resistance_level, ambos van de (0 a 100)%: si la persona tiene un eco_level mayor al de otra persona
;; dentro de su sociability_range, se aplican los rangos en su eco_level, si está entre 0 y 3, no tiene inteción de persuadir a otros, si está entre 4 y 7, la persona tal vez se
;; anime a persuadir a otro (aleatorio entre 0 y 1), si está entre 8 y 10, siempre estará dispuesto a intentar pesuadir a otros. Si se inicia un proceso de persuación de un agente
;; hacia otro, se sigue el siguiente procedimiento: si persuasion_level del emisor es mayor que change_resistance_level del receptor, el receptor aumenta su eco_level en una unidad.

;; cada persona tiene un peso de recolección r_vol asociado, el cual será tomado como semanal.
;; Mientras la persona no tenga la conciencia ecológica suficiente, este valor es asumido como reciclable no recuperado
;; que llamaremos recyclable_not_recovered_acum (mrec_nrec_ac)
;; por otra parte, acumularemos los reciclables recuperados en recyclable_recovered_cum (mrec_rec_ac)
;; también, contabilizaremos la cantidad de personas en cada rango de eco_level como:
;; - percentage_of_not-eco-friendly_people (nef_perc), porcentaje de personas con un comportamiento ecológico promedio (efprom_perc) y percentage_of_eco-friendly_people (ef_perc)

;; Las personas se moveran en el mundo, simulando la interacción que pueden tener con distintas personas que se encuentran cada semana.
;; El movimiento estará dado de forma aleatoria entre 1 y m_max por tick en cualquier dirección.

;; El numero de personas a crear en cada rango puede ser configurado antes de iniciar la simulación.
;; Las del primer rango tendran entre 1 y 3 en eco_level y un color rojo en escala (1: más rojo)
;; Análogamente para los otros dos pero en amarillo y verde.

;; El m_max es la cantidad máxima en unidades de movimiento que puede tener una persona. También se puede configurar desde el inicio.
;; El valor que resulte de un aleatorio entre 1 y m_max corresponderá a movement_value de cada agente.

;; El valor medio y la desviación estándar para generar r_vol, también podrán ser ingresados por pantalla.  (vol_mean and vol_sd)

;; Sirve para evaluar cómo podría evolucionar el nivel de conciencia ambiental promedio en una población. En cada tick se calculará un eco_level_av_pop (eco_level_pop)

globals [
  nearby         ;; se relaciona con la sociabilidad de cada humano (rango - capacidad para relacionarse con mayor o menor cantidad de vecinos cercanos)
  mrec_nrec_ac   ;; cuantificación de la cantidad de material reciclable no reciclado (monitor)
  mrec_rec_ac    ;; cuantificación de la cantidad de material reciclable reciclado (monitor)
  mat_no_recyc   ;; cuantificación de la cantidad de material no reciclable
  nef_perc       ;; # de personas en el primer rango (monitor)
  efprom_perc    ;; # de personas en el segundo rango (monitor)
  ef_perc        ;; # de personas en el tercer rango (monitor)
  eco_level_pop  ;; nivel de conciencia ambiental promedio de la población. (monitor)
]


to Setup
  clear-all
  ask patches [set pcolor 0]
  generate-population
  reset-ticks
end

to Comenzar
   ask humans [
     if (change_sociability_behavior?) [set sociability_range 1 + random sociability_max ]
     let a sociability_range
     neigborhood-type a
     let eco_level_emisor eco_level ;eco_level_emisor
     let persuasion_level_emisor eco_level ;persuasion_level_emisor
     ask patches at-points nearby [set pcolor [9] of myself]
       ask humans at-points nearby [
       let temp eco_level + (1 * (learning_rate / 100) )
       if eco_level_emisor > eco_level [
         if  eco_level_emisor >= 8 [
           set pcolor 96   ;; Inicio de intento de persuación
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
      ifelse (random 2 = 1)  ; si decide reciclar, su volumen queda clasificado como bien dispuesto, de lo contrario, se incluye como dispuesto incorrectamente
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

to generate-population
  ;; generación de humanos del primer grupo: personas no amigables con el medio ambiente (no reciclan)
  set-default-shape humans "person service"
  create-humans humanos_grupo1 [
;    set color 15 ;dar color rojo a los agentes del primer grupo
    set eco_level random 3 ; de 0 hasta 2
    set r_vol random-normal media_res desv_est_res
    set sociability_range 1 + random sociability_max    ;; el rango de sociabilidad será de 1 a 10
    set persuasion_level random-float 1
    set change_resistance_level random-float 1
  ]
  ask humans [
    set size 1.2  ;; modificar tamaño
    setxy random-pxcor random-pycor
    ifelse (show_eco_level?)
    [set label (eco_level) ]
    [set label "" ]
  ]

  ;; generación de humanos del segundo grupo: personas intermedias en cuanto a conciencia ambiental (a veces reciclan)
  set-default-shape humans "person service"
  create-humans humanos_grupo2 [
;    set color 46 ;dar color rojo a los agentes del primer grupo
    set eco_level 3 + random 5 ;desde 3 hasta 7
    set r_vol random-normal media_res desv_est_res
    set sociability_range 1 + random sociability_max    ;; el rango de sociabilidad será de 1 a 10
    set persuasion_level random-float 1
    set change_resistance_level random-float 1
  ]
  ask humans [
    set size 10  ;; modificar tamaño
    setxy random-pxcor random-pycor
    ifelse (show_eco_level?)
    [set label (eco_level) ]
    [set label "" ]
  ]

  ;; generación de humanos del tercer grupo: personas con conciencia ambiental (siempre reciclan)
  set-default-shape humans "person service"
  create-humans humanos_grupo3 [
;    set color 64 ;dar color rojo a los agentes del primer grupo
    set eco_level 8 + random 3 ;desde 8 hasta 10
    set r_vol random-normal media_res desv_est_res
    set sociability_range 1 + random sociability_max    ;; el rango de sociabilidad será de 1 a 10
    set persuasion_level random-float 1
    set change_resistance_level random-float 1
  ]
  ask humans [
    set size 1.5  ;; modificar tamaño
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
402
10
902
511
-1
-1
12.0
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

TEXTBOX
13
10
361
43
Conciencia ambiental & REP
25
0.0
1

SLIDER
147
85
264
118
humanos_grupo1
humanos_grupo1
1
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
146
132
265
165
humanos_grupo2
humanos_grupo2
1
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
147
182
269
215
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
146
236
273
269
desplazamiento_max
desplazamiento_max
1
20
7.0
1
1
NIL
HORIZONTAL

INPUTBOX
299
262
391
322
media_res
0.63
1
0
Number

INPUTBOX
300
325
391
385
desv_est_res
0.3
1
0
Number

TEXTBOX
153
50
272
89
Cantidad inicial de personas de cada grupo
10
0.0
1

TEXTBOX
13
234
143
273
Desplazamiento máximo permitido de las personas por unidad de tiempo
10
0.0
1

BUTTON
195
488
306
521
Comenzar
Comenzar
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
82
488
185
521
Inicializar
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
143
447
278
480
show_eco_level?
show_eco_level?
0
1
-1000

CHOOSER
146
335
275
380
sociability_range_type
sociability_range_type
"Moore" "Von Neumann"
0

SLIDER
74
393
175
426
sociability_max
sociability_max
1
10
3.0
1
1
NIL
HORIZONTAL

MONITOR
1209
11
1322
56
Material no reciclado
mrec_nrec_ac
4
1
11

PLOT
914
12
1200
175
Cantidad (Kg) vs Tiempo
Tiempo 
Volumen
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Material no reciclado" 1.0 0 -2674135 true "" "plot mrec_nrec_ac"
"Material reciclado" 1.0 0 -13840069 true "" "plot mrec_rec_ac"
"Material no reciclable" 1.0 0 -12895429 true "" "plot mat_no_recyc"
"Total" 1.0 0 -1513240 true "" "plot (mrec_nrec_ac + mrec_rec_ac + mat_no_recyc)"

MONITOR
1209
64
1322
109
Material reciclado
mrec_rec_ac
4
1
11

MONITOR
1221
182
1316
227
# Personas G1
nef_perc
17
1
11

MONITOR
1222
233
1317
278
# Personas G2
efprom_perc
17
1
11

MONITOR
1223
289
1318
334
# Personas G3
ef_perc
17
1
11

MONITOR
1013
355
1246
400
Nivel ecológico promedio de la población
eco_level_pop
8
1
11

PLOT
913
189
1189
339
Número de personas vs tiempo
Tiempo
# de personas
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
303
226
400
270
Media y desviación de residuos (kg/habitante/día)
9
0.0
1

TEXTBOX
10
83
131
125
Personas con baja o nula conciencia ambiental (no reciclan)
10
0.0
1

TEXTBOX
11
133
132
172
Personas con nivel medio de conciencia ambiental (a veces reciclan)
10
0.0
1

TEXTBOX
12
181
133
220
Personas con alto nivel de conciencia ambiental (siempre reciclan)
10
0.0
1

TEXTBOX
285
51
406
77
Porcentaje de residuos potencialmente reciclables
10
0.0
1

SLIDER
277
86
398
119
recyc_perc_g1
recyc_perc_g1
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
276
132
398
165
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
277
183
397
216
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
1211
116
1324
161
Material no reciclable
mat_no_recyc
4
1
11

PLOT
917
409
1318
529
Nivel ecológico promedio de la población
Tiempo
Eco_nivel
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
308
393
398
426
change_sociability_behavior?
change_sociability_behavior?
1
1
-1000

TEXTBOX
193
393
303
437
¿Permitir cambio de rango máximo de sociabilidad durante la ejecución?
9
0.0
1

SLIDER
146
284
272
317
learning_rate
learning_rate
0
100
4.0
1
1
%
HORIZONTAL

TEXTBOX
12
286
126
312
Tasa de aprendizaje de los individuos
10
0.0
1

TEXTBOX
54
338
179
369
Tipo de rango de sociabilidad
10
0.0
1

TEXTBOX
3
394
77
423
Rango máximo de sociabilidad
10
0.0
1

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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment22" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>Comenzar</go>
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
  <experiment name="experiment" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>Comenzar</go>
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
