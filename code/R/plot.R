library(tidyverse)

data <- "out1"
dir <- "../03-graphgrid-SIR/outdata/"
df <- read_csv(paste0(dir, data, ".csv"))

df %>%
  filter(x_pos_infected_at != 0) %>%
  # filter(ensemble == 10) %>%
  ggplot(aes(x = x_pos_infected_at, y = y_pos_infected_at)) +
  geom_density2d_filled() +
  scale_fill_viridis_d(option = "plasma") +
  geom_point(alpha = .2, size = 2.5, colour = "red") +
  theme_minimal() +
  labs(x = "", y = "") +
  lims(x = c(0, 1500), y = c(0, 1000)) +
  theme(legend.position = "none",
        axis.text = element_blank(),
        panel.grid = element_blank())
ggsave(paste0(dir, data, ".png"), width = 1500, height = 1000, dpi = 300, units = "px")

r0 <- df %>% filter(x_pos_infected_at == 0) %>% pull(num_infected) %>% mean()
r0