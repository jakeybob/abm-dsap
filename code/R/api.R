library(tidyverse)
library(httr)

N = 500
I0 = 5
nsteps = 400

# url is IP, plus port of listener
url = paste0("http://192.168.1.15:8888/abm_args/", N, "/", I0, "/", nsteps)
a <- GET(url = url)
a$content %>% rawToChar() # outputs sum of input arguments as a check
a$status_code # 200 = success!
a

macos_path <- "//Volumes/downloads/data.csv" # modify srvr.jl to output here
df <- read_csv(macos_path)

df %>% 
  pivot_longer(cols = ends_with("status")) %>% 
  ggplot(aes(x = step, y = value, fill = name, colour = name)) +
  geom_point() + geom_line() + theme_bw() +
  labs(x = "time", y = "N. agents", title = "R / Julia Agents API") +
  theme(plot.title = element_text(face = "bold", size = 30))
