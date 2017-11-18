library(png)
library(ggplot2)
library(grid)
library(gridExtra)
library(rasterVis)

studyFolder <- "~/Dropbox/hip_fracture/"
exportFolder <- "/Users/yuxitian/Dropbox/Hip_Fracture_Paper/FiguresWithLabels/"

# folders <- c("PPlus",
#              "Optum_JRD", "CCAE_JRD", "CCAE_UNM",
#              "MDCR_JRD", "MDCR_UNM", "MDCD_JRD", "Cerner",
#              "Columbia", "Stride")
# label1 <- c("IMS",
#             "Optum", "Truven", "Truven",
#             "Truven", "Truven", "Truven", "Cerner",
#             "Columbia", "Stanford")
# label2 <-  c("P-Plus",
#              "CEDM", expression(CCAE^1), expression(CCAE^2),
#              expression(MDCR^1), expression(MDCR^2), "MDCD" ,"UT" ,
#              "" , "")
# label3 <- c("IMS PPlus",
#             "Optum CEDM",
#             "Truven CCAE (1)", "Truven CCAE (2)",
#             "Truven MDCR (1)", "Truven MDCR (2)",
#             "Truven MDCD",
#             "Cerner UT", "Columbia", "Stanford")

folders <- c("PPlus",
             "Optum_JRD", "CCAE_JRD", "CCAE_UNM",
             "MDCR_JRD", "MDCR_UNM", "MDCD_JRD", "Cerner",
             "Columbia", "Stride", "NHIS")

label1 <- c("IMS",
            "Optum", "Truven", "Truven",
            "Truven", "Truven", "Truven", "Cerner",
            "Columbia", "Stanford")

label2 <-  c("P-Plus",
             "CEDM", expression(CCAE^1), expression(CCAE^2),
             expression(MDCR^1), expression(MDCR^2), "MDCD" ,"UT" ,
             "" , "")

label3 <- c("IMS P-Plus",
            "Optum CEDM",
            "Truven CCAE (1)", "Truven CCAE (2)",
            "Truven MDCR (1)", "Truven MDCR (2)",
            "Truven MDCD",
            "Cerner UT", "Columbia", "Stanford")

folders = folders[c(1,2,3,5,7,8,9,10)]
label1 = label1[c(1,2,3,5,7,8,9,10)]
label2 = label2[c(1,2,3,5,7,8,9,10)]
label3 = label3[c(1,2,3,5,7,8,9,10)]
label2[3:4] = c("CCAE", "MDCR")
label3[3:4] = c("Truven CCAE", "Truven MDCR")

## add label to each plot

# Attrition
setwd(file.path(paste0(exportFolder,"Attrition")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"tablesAndFigures", "Attrition.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.85, y = 1, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 2400, height = 2800)
  dev.off()
})


# KM
setwd(file.path(paste0(exportFolder,"KM")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"KaplanMeier.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  #rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.50, y = .97, paste0(label1[idx], " ", label2[idx]),cex = 4, col = "black")
  rasterImage(base[1:1600,], lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  rect(.493, .94, .565, .985, col = 'white', border = 'white')
  rect(.61, .94, .712, .985, col = 'white', border = 'white')
  text(.405, .968, "Alendronate", cex = 4, col = "black")
  text(.655, .968, "Raloxifene", cex = 4, col = "black")
  rect(-.1, 0.3, 0.05, 0.7, col = 'white', border = 'white')
  text(0.06, 0.5, "Survival Probability", cex = 5, col = "black", srt = 90)
  dev.copy(png,paste0(folder,".png"),width = 2800, height = 1600)
  dev.off()
})


# kmtext <- lapply(1:length(folders), FUN = function(idx) {
#   folder <- folders[idx]
#   readPNG(file.path(paste0(exportFolder,"/KM/",folder,".png")))
# })
#
# layout <- par(fin=c(1, 2))
# ggsave("multiKM.png",width=8.5, height=11, marrangeGrob(grobs=kmtext, nrow=5, ncol=2,top=NULL))
#
# multiplot(plotlist = kmtext, cols = 2)
# dev.copy(png,"multiKM.png",width = 2800, height = 2000)
# dev.off()

# Ps
setwd(file.path(paste0(exportFolder,"/Ps")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"Ps.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  # rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.9, y = 1, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  rect(0.865, 0.45, 1.05, 0.6, col = 'white', border = 'white')
  text(0.94, 0.582, "Alendronate", cex = 4, col = "black")
  text(0.9305, 0.508, "Raloxifene", cex = 4, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 2000, height = 1400)
  dev.off()
})

base <- as.raster(readPNG("PsAfterStratificationPrefScale.png"))
rasterGrob(base, interpolate = FALSE)
par(mar = c(0,0,0,0))
plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
lim <- par()
rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
rect(0.865, 0.45, 1.05, 0.6, col = 'white', border = 'white')
text(0.94, 0.582, "Alendronate", cex = 4, col = "black")
text(0.9305, 0.508, "Raloxifene", cex = 4, col = "black")
dev.copy(png,"PsAfter_Optum.png",width = 2000, height = 1400)
dev.off()



# PsAfterStratification
setwd(file.path(paste0(exportFolder,"/PsAfterStratification")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"PsAfterStratification.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.9, y = 1, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 2800, height = 2000)
  dev.off()
})

# PsAfterStratificationPrefScale
setwd(file.path(paste0(exportFolder,"/PsAfterStratificationPrefScale")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"PsAfterStratificationPrefScale.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  # rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.9, y = 1, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  rect(0.865, 0.45, 1.05, 0.6, col = 'white', border = 'white')
  text(0.94, 0.582, "Alendronate", cex = 4, col = "black")
  text(0.9305, 0.508, "Raloxifene", cex = 4, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 2000, height = 1400)
  dev.off()
})

# PsPrefScale
setwd(file.path(paste0(exportFolder,"/PsPrefScale")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"PsPrefScale.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  # rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.9, y = 1, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  rect(0.865, 0.45, 1.05, 0.6, col = 'white', border = 'white')
  text(0.94, 0.582, "Alendronate", cex = 4, col = "black")
  text(0.9305, 0.508, "Raloxifene", cex = 4, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 2000, height = 1400)
  dev.off()
})

# BalanceTopVariables
setwd(file.path(paste0(exportFolder,"/BalanceTopVariables")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"tablesAndFigures", "BalanceTopVariables.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.15, y = 1, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 4000, height = 2400)
  dev.off()
})

# BalanceScatterPlot
setwd(file.path(paste0(exportFolder,"/BalanceScatterPlot")))
lapply(1:length(folders), FUN = function(idx) {
  folder <- folders[idx]
  base <- as.raster(readPNG(file.path(studyFolder,folder,"tablesAndFigures", "BalanceScatterPlot.png")))
  rasterGrob(base, interpolate = FALSE)
  par(mar = c(0,0,0,0))
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  lim <- par()
  rasterImage(base, lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])+text(x = 0.8, y = 0.9, paste0(label1[idx], " ", label2[idx]),cex = 8, col = "black")
  dev.copy(png,paste0(folder,".png"),width = 1800, height = 1800)
  dev.off()
})


# # multiplot
# multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL, byrow = FALSE) {
#   library(grid)
#   plots <- c(list(...), plotlist)
#   numPlots = length(plots)
#   if (is.null(layout)) {
#     layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
#                      ncol = cols, nrow = ceiling(numPlots/cols), byrow = byrow)
#   }
#
#   if (numPlots==1) {
#     print(plots[[1]])
#
#   } else {
#     grid.newpage()
#     pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
#     for (i in 1:numPlots) {
#       matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
#       print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
#                                       layout.pos.col = matchidx$col))
#     }
#   }
# }
#
# kmtext <- lapply(1:length(folders), FUN = function(idx) {
#   folder <- folders[idx]
#   base <- as.raster(readPNG(file.path(paste0(exportFolder,"KM",folder,".png"))))
#   grid.newpage()
#   rasterGrob(base, interpolate = FALSE)
# })
#
#
# # save
# ggsave(filename="com-attrition.png",plot=p,device="png", path = file.path("/Users/yang/Downloads/AlendronateVsRaloxifene/FiguresAttritionFolder"))
# ggsave("multipage.pdf", kmtext)
# writePNG(plotkm,"kmplot.png")
#
#
# grid.arrange(grobs = kmtext, ncol=2)
# do.call("grid.arrange", c(grobs = km, ncol=2))
#
#
# k <- multiplot(plotlist = kmtext, cols = 2)
# writePNG(k,"plot.png")

