# Análisis del Mercado Laboral — ETOI 2025

Trabajo Práctico de análisis de datos en R sobre la **Encuesta Trimestral de Ocupación e Ingresos (ETOI)**, 4to trimestre 2025, Ciudad Autónoma de Buenos Aires.

---

## Estructura del proyecto

```
proyecto/
│
├── dataset/
│   └── etoi254_usu_ind.txt       # Dataset original
│
├── plots/                         # Gráficos generados 
│   ├── grafico_P1_tasas_mercado_laboral.png
│   ├── grafico_P2_empleo_segun_sexo.png
│   ├── grafico_P3_ingreso_por_educacion.png
│   ├── grafico_P4_categoria_ocupacional.png
│   └── grafico_P5_brecha_ingresos.png
│
├── tablas/                        # Tablas CSV generadas 
│   ├── tabla_P1_tasas_mercado.csv
│   ├── tabla_P2_empleo_segun_sexo.csv
│   ├── tabla_P3_ingreso_por_educacion.csv
│   ├── tabla_P4_categoria_ocupacional.csv
│   └── tabla_P5_brecha_ingresos.csv
│
├── tp_etoi_analisis.R             # Script principal de análisis
└── readme.md                     
```

> Las carpetas `plots/` y `tablas/` se crean automáticamente al ejecutar el script. No hace falta crearlas a mano.

---

## Requisitos

### Software
- R (versión 4.2 o superior)
- RStudio (recomendado)

### Paquetes de R
```r
install.packages("tidyverse")   # dplyr, ggplot2, tidyr, readr, forcats
install.packages("scales")      # formateo de ejes en gráficos
```

Ejecutar `install.packages()` solo la primera vez. Luego dejar esas líneas comentadas en el script.

---

## Cómo ejecutar el análisis

1. Descargar el ZIP del dataset desde el sitio de la DGEyC — GCBA.
2. Descomprimir y colocar el archivo `etoi254_usu_ind.txt` dentro de la carpeta `dataset/`.
3. Abrir `tp_etoi_analisis.R` en RStudio.
4. Ejecutar el script

Los gráficos y tablas se guardan automáticamente en sus respectivas carpetas.

---

## Fuente de datos

| Campo | Detalle |
|---|---|
| **Encuesta** | Encuesta Trimestral de Ocupación e Ingresos (ETOI) |
| **Período** | 4to trimestre 2025 |
| **Ámbito** | Ciudad Autónoma de Buenos Aires |
| **Organismo** | Dirección General de Estadística y Censos (DGEyC) — GCBA |
| **Archivo** | `etoi254_usu_ind.txt` (separador: `;`) |

---

## Variables utilizadas

| Variable en el dataset | Descripción | Valores |
|---|---|---|
| `estado` | Condición de actividad | 1 = Ocupado, 2 = Desocupado, 3 = Inactivo |
| `sexo` | Sexo del entrevistado | 1 = Varón, 2 = Mujer |
| `nivel_2` | Nivel educativo alcanzado | 1 a 6 (ver script), 9 = Ns/Nc |
| `categori` | Categoría ocupacional | 1 = Patrón, 2 = Cta. propia, 3 = Asalariado, 4 = Trab. familiar, 9 = Ns/Nc |
| `inglab_2` | Ingreso de la ocupación principal | Valor en pesos. 0 o NA = sin dato |

---

## Análisis realizados

### Punto 1 — Tasas del mercado laboral
Cálculo de tres indicadores sobre la población total:

- **Tasa de actividad** = (Ocupados + Desocupados) / Total × 100
- **Tasa de empleo** = Ocupados / Total × 100
- **Tasa de desocupación** = Desocupados / (Ocupados + Desocupados) × 100

> La tasa de desocupación se calcula sobre la Población Económicamente Activa (PEA), no sobre el total.

### Punto 2 — Tasa de empleo según sexo
Desagregación de la tasa de empleo por sexo para detectar diferencias en el acceso al trabajo. El denominador de cada tasa es el total de cada grupo (varones / mujeres), no la población total.

### Punto 3 — Ingreso promedio según nivel educativo
Ingreso promedio de la ocupación principal para personas **ocupadas** con ingreso declarado mayor a cero, agrupadas por nivel educativo. Permite evaluar el retorno económico de la educación.

### Punto 4 — Distribución por categoría ocupacional
Proporciones de ocupados según su posición en el proceso productivo (patrón, cuenta propia, asalariado, trabajador familiar). Base: total de ocupados.

### Punto 5 — Brecha de ingresos por sexo
Diferencia porcentual entre el ingreso promedio (y mediana) de varones y mujeres ocupados. Se presentan ambas medidas porque el promedio es sensible a ingresos muy altos, mientras que la mediana es más robusta.

---

## Decisiones metodológicas

**Valores Ns/Nc tratados como NA**
Los valores `9` en `nivel_2` y `categori` representan "No sabe / No contesta" según el diseño de registros de la encuesta. Se convierten a `NA_character_` en la etapa de wrangling y se excluyen automáticamente de los análisis con `filter(!is.na(...))`.

**Ingresos igual a cero excluidos**
Los registros con `inglab_2 == 0` pueden reflejar trabajo familiar no remunerado o errores de carga. Se excluyen de los análisis de ingreso (puntos 3 y 5) con `filter(inglab_2 > 0)`.

**Sin ponderadores**
El análisis se realiza sobre la muestra sin aplicar el factor de expansión, lo cual es válido como ejercicio académico. En un análisis profesional se utilizaría el ponderador en cada `summarise()` para estimar correctamente la población total.

**Tema visual único**
Todos los gráficos comparten el objeto `tema_etoi` y la paleta `colores_sexo`, garantizando consistencia visual sin repetir código.