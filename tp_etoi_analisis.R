
# Trabajo Práctico — Análisis ETOI 4to trimestre 2025
# DGEyC — GCBA | Encuesta Trimestral de Ocupación e Ingresos


library(tidyverse)
library(scales)



# IMPORTACIÓN

df_raw <- read_delim("dataset/etoi254_usu_ind.txt", delim = ";")

print(paste("Filas cargadas:", nrow(df_raw)))
glimpse(df_raw[, 1:10])



# EXPLORACIÓN INICIAL
# Verificar valores reales de cada variable antes de continuar.


df_raw %>% count(estado)
df_raw %>% count(sexo)
df_raw %>% count(nivel_2)
df_raw %>% count(categori)
summary(df_raw$inglab_2)



# DATA WRANGLING
# Se crean etiquetas legibles para las variables categóricas.
# Los códigos sin correspondencia válida se asignan a NA y quedan excluidos
# de los análisis subsiguientes.


base_laboral <- df_raw %>%
  mutate(
    
    sexo_etiqueta = case_when(
      sexo == 1 ~ "Varón",
      sexo == 2 ~ "Mujer",
      TRUE      ~ "No registrado"
    ),
    
    estado_etiqueta = case_when(
      estado == 1 ~ "Ocupado",
      estado == 2 ~ "Desocupado",
      estado == 3 ~ "Inactivo",
      TRUE        ~ "Menores/Otros"
    ),
    
    nivel_educativo = case_when(
      nivel_2 == 1 ~ "Primario incompleto o menos",
      nivel_2 == 2 ~ "Primario completo",
      nivel_2 == 3 ~ "Secundario incompleto",
      nivel_2 == 4 ~ "Secundario completo",
      nivel_2 == 5 ~ "Superior incompleto",
      nivel_2 == 6 ~ "Superior completo",
      TRUE         ~ NA_character_
    ),
  
    nivel_educativo = factor(nivel_educativo, levels = c(
      "Primario incompleto o menos", "Primario completo",
      "Secundario incompleto",       "Secundario completo",
      "Superior incompleto",         "Superior completo"
    )),
    
    categoria_ocupacional = case_when(
      categori == 1 ~ "Patrón",
      categori == 2 ~ "Cuenta propia",
      categori == 3 ~ "Asalariado",
      categori == 4 ~ "Trabajador familiar sin remuneración",
      TRUE          ~ NA_character_
    )
  )



# TEMA VISUAL


tema_etoi <- theme_minimal(base_size = 12) +
  theme(
    plot.title         = element_text(face = "bold", size = 14, hjust = 0),
    plot.subtitle      = element_text(color = "grey40", size = 11, hjust = 0,
                                      margin = margin(b = 10)),
    plot.caption       = element_text(color = "grey55", size = 9, hjust = 0,
                                      margin = margin(t = 10)),
    axis.title         = element_text(size = 10, color = "grey30"),
    axis.text          = element_text(size = 10, color = "black"),
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position    = "bottom",
    legend.title       = element_blank(),
    plot.margin        = margin(15, 20, 10, 15)
  )

colores_sexo <- c("Varón" = "#f28e2b", "Mujer" = "#4e79a7")
fuente_datos <- "Fuente: DGEyC — GCBA. ETOI, 4to trimestre 2025."

dir.create("plots",  showWarnings = FALSE)
dir.create("tablas", showWarnings = FALSE)



# PUNTO 1 — Tasas del mercado laboral
#
# Tasa de actividad    = PEA / Población total × 100
# Tasa de empleo       = Ocupados / Población total × 100
# Tasa de desocupación = Desocupados / PEA × 100


tasas_totales <- base_laboral %>%
  summarise(
    Poblacion_Total = n(),
    Ocupados        = sum(estado == 1),
    Desocupados     = sum(estado == 2),
    Inactivos       = sum(estado == 3)
  ) %>%
  mutate(
    PEA               = Ocupados + Desocupados,
    Tasa_Actividad    = round((PEA         / Poblacion_Total) * 100, 1),
    Tasa_Empleo       = round((Ocupados    / Poblacion_Total) * 100, 1),
    Tasa_Desocupacion = round((Desocupados / PEA)             * 100, 1)
  )

print(tasas_totales)

tasas_largo <- tasas_totales %>%
  select(Tasa_Actividad, Tasa_Empleo, Tasa_Desocupacion) %>%
  pivot_longer(everything(), names_to = "indicador", values_to = "valor") %>%
  mutate(
    indicador = case_match(
      indicador,
      "Tasa_Actividad"    ~ "Actividad",
      "Tasa_Empleo"       ~ "Empleo",
      "Tasa_Desocupacion" ~ "Desocupación"
    ),
    indicador = factor(indicador, levels = c("Actividad", "Empleo", "Desocupación"))
  )

grafico_p1 <- ggplot(tasas_largo, aes(x = indicador, y = valor, fill = indicador)) +
  geom_bar(stat = "identity", width = 0.55, show.legend = FALSE) +
  geom_text(aes(label = paste0(valor, "%")), vjust = -0.5, size = 4.5, fontface = "bold") +
  scale_fill_manual(values = c(
    "Actividad"    = "#2471A3",
    "Empleo"       = "#1E8449",
    "Desocupación" = "#C0392B"
  )) +
  scale_y_continuous(limits = c(0, 100), labels = label_percent(scale = 1, suffix = "%")) +
  labs(
    title    = "Tasas del mercado laboral",
    subtitle = "Ciudad Autónoma de Buenos Aires — ETOI, 4to trimestre 2025",
    x = NULL, y = "Porcentaje (%)", caption = fuente_datos
  ) +
  tema_etoi

print(grafico_p1)
ggsave("plots/grafico_P1_tasas_mercado_laboral.png", grafico_p1,
       width = 7, height = 5, dpi = 300, bg = "white")



# PUNTO 2 — Tasa de empleo según sexo
# El denominador es el total de cada grupo (no la población total).


tasa_empleo_sexo <- base_laboral %>%
  filter(sexo_etiqueta %in% c("Varón", "Mujer")) %>%
  group_by(sexo_etiqueta) %>%
  summarise(
    Poblacion_Grupo = n(),
    Ocupados_Grupo  = sum(estado == 1),
    Tasa_Empleo     = round((Ocupados_Grupo / Poblacion_Grupo) * 100, 1),
    .groups = "drop"
  )

print(tasa_empleo_sexo)

# Diferencia calculada de forma explícita para evitar dependencia del orden de filas
tasa_varon <- tasa_empleo_sexo %>% filter(sexo_etiqueta == "Varón") %>% pull(Tasa_Empleo)
tasa_mujer <- tasa_empleo_sexo %>% filter(sexo_etiqueta == "Mujer") %>% pull(Tasa_Empleo)
dif_pp <- round(abs(tasa_varon - tasa_mujer), 1)

grafico_p2 <- ggplot(tasa_empleo_sexo,
                     aes(x = sexo_etiqueta, y = Tasa_Empleo, fill = sexo_etiqueta)) +
  geom_bar(stat = "identity", width = 0.45, show.legend = FALSE) +
  geom_text(aes(label = paste0(Tasa_Empleo, "%")), vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = colores_sexo) +
  scale_y_continuous(limits = c(0, 100), labels = label_percent(scale = 1, suffix = "%")) +
  labs(
    title    = "Tasa de empleo según sexo",
    subtitle = paste0("Diferencia: ", dif_pp, " puntos porcentuales\n",
                      "Ciudad Autónoma de Buenos Aires — ETOI, 4to trimestre 2025"),
    x = "Sexo", y = "Tasa de empleo (%)", caption = fuente_datos
  ) +
  tema_etoi

print(grafico_p2)
ggsave("plots/grafico_P2_empleo_segun_sexo.png", grafico_p2,
       width = 6, height = 5, dpi = 300, bg = "white")



# PUNTO 3 — Ingreso promedio según nivel educativo (solo ocupados)
# Se excluyen registros con inglab_2 = 0 (pueden corresponder a trabajo
# familiar sin remuneración). Solo se grafican los niveles con casos válidos.


ingreso_educacion <- base_laboral %>%
  filter(estado == 1, !is.na(nivel_educativo), inglab_2 > 0) %>%
  group_by(nivel_educativo) %>%
  summarise(
    Cantidad_Ocupados = n(),
    Ingreso_Promedio  = round(mean(inglab_2, na.rm = TRUE), 0),
    .groups = "drop"
  )

print(ingreso_educacion)

grafico_p3 <- ggplot(ingreso_educacion, aes(x = Ingreso_Promedio, y = nivel_educativo)) +
  geom_bar(stat = "identity", fill = "#2471A3", width = 0.65) +
  geom_text(
    aes(label = paste0("$", format(Ingreso_Promedio, big.mark = ".", scientific = FALSE))),
    hjust = -0.08, size = 3.5, color = "grey25"
  ) +
  scale_x_continuous(
    limits = c(0, max(ingreso_educacion$Ingreso_Promedio) * 1.28),
    labels = label_dollar(prefix = "$", big.mark = ".", decimal.mark = ",", accuracy = 1)
  ) +
  labs(
    title    = "Ingreso promedio de la ocupación principal según nivel educativo",
    subtitle = "Solo ocupados con ingreso declarado mayor a cero\nCiudad Autónoma de Buenos Aires — ETOI, 4to trimestre 2025",
    x = "Ingreso promedio mensual ($)", y = NULL, caption = fuente_datos
  ) +
  tema_etoi +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "grey85")
  )

print(grafico_p3)
ggsave("plots/grafico_P3_ingreso_por_educacion.png", grafico_p3,
       width = 9, height = 5.5, dpi = 300, bg = "white")



# PUNTO 4 — Distribución por categoría ocupacional (solo ocupados)


distribucion_categoria <- base_laboral %>%
  filter(estado == 1, !is.na(categoria_ocupacional)) %>%
  count(categoria_ocupacional) %>%
  mutate(
    Proporcion = round(n / sum(n), 3),
    Porcentaje = round(Proporcion * 100, 1)
  ) %>%
  arrange(desc(Porcentaje)) %>%
  mutate(categoria_ocupacional = fct_inorder(categoria_ocupacional))

print(distribucion_categoria)

grafico_p4 <- ggplot(distribucion_categoria, aes(x = Porcentaje, y = categoria_ocupacional)) +
  geom_bar(stat = "identity", fill = "#1A5276", width = 0.6) +
  geom_text(
    aes(label = paste0(Porcentaje, "%")),
    hjust = -0.1, size = 4, fontface = "bold", color = "grey20"
  ) +
  scale_x_continuous(
    limits = c(0, max(distribucion_categoria$Porcentaje) * 1.22),
    labels = label_percent(scale = 1, suffix = "%")
  ) +
  labs(
    title    = "Distribución de ocupados según categoría ocupacional",
    subtitle = "Solo personas ocupadas\nCiudad Autónoma de Buenos Aires — ETOI, 4to trimestre 2025",
    x = "Porcentaje sobre total de ocupados (%)", y = NULL, caption = fuente_datos
  ) +
  tema_etoi +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "grey85")
  )

print(grafico_p4)
ggsave("plots/grafico_P4_categoria_ocupacional.png", grafico_p4,
       width = 9, height = 5, dpi = 300, bg = "white")



# PUNTO 5 — Brecha de ingresos por sexo (solo ocupados)
# Se reportan promedio y mediana. El promedio es sensible a valores extremos;
# la mediana ofrece una medida más robusta de la tendencia central.
# Fórmula: brecha (%) = (ingreso_varones − ingreso_mujeres) / ingreso_varones × 100


brecha_ingresos <- base_laboral %>%
  filter(estado == 1, inglab_2 > 0, sexo_etiqueta %in% c("Varón", "Mujer")) %>%
  group_by(sexo_etiqueta) %>%
  summarise(
    Ingreso_Medio   = round(mean(inglab_2,   na.rm = TRUE), 0),
    Ingreso_Mediana = round(median(inglab_2, na.rm = TRUE), 0),
    .groups = "drop"
  )

print(brecha_ingresos)

ing_prom_v <- brecha_ingresos %>% filter(sexo_etiqueta == "Varón") %>% pull(Ingreso_Medio)
ing_prom_m <- brecha_ingresos %>% filter(sexo_etiqueta == "Mujer") %>% pull(Ingreso_Medio)
ing_med_v  <- brecha_ingresos %>% filter(sexo_etiqueta == "Varón") %>% pull(Ingreso_Mediana)
ing_med_m  <- brecha_ingresos %>% filter(sexo_etiqueta == "Mujer") %>% pull(Ingreso_Mediana)

brecha_prom <- round((ing_prom_v - ing_prom_m) / ing_prom_v * 100, 1)
brecha_med  <- round((ing_med_v  - ing_med_m)  / ing_med_v  * 100, 1)

brecha_largo <- brecha_ingresos %>%
  pivot_longer(c(Ingreso_Medio, Ingreso_Mediana), names_to = "medida", values_to = "valor") %>%
  mutate(
    medida = case_match(
      medida,
      "Ingreso_Medio"   ~ paste0("Promedio\n(brecha: ", brecha_prom, "%)"),
      "Ingreso_Mediana" ~ paste0("Mediana\n(brecha: ",  brecha_med,  "%)")
    ),
    medida = factor(medida, levels = c(
      paste0("Promedio\n(brecha: ", brecha_prom, "%)"),
      paste0("Mediana\n(brecha: ",  brecha_med,  "%)")
    ))
  )

grafico_p5 <- ggplot(brecha_largo, aes(x = sexo_etiqueta, y = valor, fill = sexo_etiqueta)) +
  geom_bar(stat = "identity", width = 0.5, show.legend = FALSE) +
  geom_text(
    aes(label = paste0("$ ", format(valor, big.mark = ".", scientific = FALSE))),
    vjust = -0.5, fontface = "bold", size = 4.5
  ) +
  facet_wrap(~medida) +
  scale_fill_manual(values = colores_sexo) +
  scale_y_continuous(
    limits = c(0, max(brecha_largo$valor) * 1.22),
    labels = label_dollar(prefix = "$", big.mark = ".", decimal.mark = ",", accuracy = 1)
  ) +
  labs(
    title    = "Brecha de ingresos de la ocupación principal por sexo",
    subtitle = "Solo ocupados con ingreso declarado mayor a cero\nCiudad Autónoma de Buenos Aires — ETOI, 4to trimestre 2025",
    x = "Sexo del entrevistado", y = "Ingreso ($)", caption = fuente_datos
  ) +
  tema_etoi +
  theme(strip.text = element_text(face = "bold", size = 11))

print(grafico_p5)
ggsave("plots/grafico_P5_brecha_ingresos.png", grafico_p5,
       width = 9, height = 5.5, dpi = 300, bg = "white")



# EXPORTACIÓN DE TABLAS


write_csv(tasas_totales,          "tablas/tabla_P1_tasas_mercado.csv")
write_csv(tasa_empleo_sexo,       "tablas/tabla_P2_empleo_segun_sexo.csv")
write_csv(ingreso_educacion,      "tablas/tabla_P3_ingreso_por_educacion.csv")
write_csv(distribucion_categoria, "tablas/tabla_P4_categoria_ocupacional.csv")
write_csv(brecha_ingresos,        "tablas/tabla_P5_brecha_ingresos.csv")

cat("\nAnálisis finalizado. Gráficos en plots/ | Tablas en tablas/\n")