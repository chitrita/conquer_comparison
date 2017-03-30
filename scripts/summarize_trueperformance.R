summarize_trueperformance <- function(figdir, datasets, exts, dtpext, cols,
                                      singledsfigdir, cobradir, concordancedir, 
                                      dschardir, origvsmockdir) {

  ## Generate list to hold all plots
  plots <- list()
  
  ## ----------------------------- Heatmaps --------------------------------- ##
  pdf(paste0(figdir, "/summary_trueperformance", exts, dtpext, "_1.pdf"),
      width = 10, height = 4 * length(datasets))
  
  ## Read all true FDR/TPR information
  fdrtpr <- do.call(rbind, lapply(datasets, function(ds) {
    do.call(rbind, lapply(exts, function(e) {
      readRDS(paste0(singledsfigdir, "/performance_realtruth/", ds, e, 
                     "_performance_realtruth_summary_data.rds"))$FDRTPR
    }))
  }))
  ## Read all true AUROC information
  auroc <- do.call(rbind, lapply(datasets, function(ds) {
    do.call(rbind, lapply(exts, function(e) {
      readRDS(paste0(singledsfigdir, "/performance_realtruth/", ds, e, 
                     "_performance_realtruth_summary_data.rds"))$AUROC
    }))
  }))
  
  cols <- structure(cols, names = gsub(paste(exts, collapse = "|"), "", names(cols)))
  
  for (f in unique(fdrtpr$filt)) {
    for (asp in c("FDR", "TPR")) {
      ## Heatmap of true FDRs and TPRs at padj=0.05 threshold
      y <- fdrtpr %>% 
        dplyr::filter(filt == f) %>%
        dplyr::filter(thr == "thr0.05") %>%
        tidyr::separate(method, c("method", "n_samples", "repl"), sep = "\\.") %>%
        dplyr::mutate(method = gsub(paste(exts, collapse = "|"), "", method)) %>%
        dplyr::mutate(dataset = paste0(dataset, ".", filt, ".", n_samples, ".", repl)) %>%
        dplyr::select_("method", "dataset", asp) %>%
        reshape2::dcast(dataset ~ method, value.var = asp) %>%
        tidyr::separate(dataset, c("ds", "filt", "n_samples", "repl"), sep = "\\.", remove = FALSE) %>%
        dplyr::arrange(ds, as.numeric(as.character(n_samples))) %>% 
        dplyr::select(-ds, -filt, -n_samples, -repl)  %>% as.data.frame()
      rownames(y) <- y$dataset
      y$dataset <- NULL
      
      annotation_row = data.frame(id = rownames(y)) %>% 
        tidyr::separate(id, c("dataset", "filt", "n_samples", "repl"), sep = "\\.", remove = FALSE) %>%
        dplyr::mutate(n_samples = factor(n_samples, 
                                         levels = as.character(sort(unique(as.numeric(as.character(n_samples)))))))
      rownames(annotation_row) <- annotation_row$id
      
      pheatmap(y, cluster_rows = FALSE, cluster_cols = FALSE, scale = "none", 
               main = paste0("True ", asp, " at adj.p=0.05 cutoff, ", f),
               display_numbers = TRUE, 
               color = colorRampPalette(rev(brewer.pal(n = 7, name = "RdYlBu")))(100),
               breaks = seq(0, 1, length.out = 101), 
               annotation_row = dplyr::select(annotation_row, n_samples, dataset), 
               show_rownames = FALSE,
               annotation_col = data.frame(method = colnames(y), row.names = colnames(y)),
               annotation_colors = list(method = cols[colnames(y)]),
               annotation_names_col = FALSE)
    }
  }
  dev.off()

  ## ------------------------------- Performance ------------------------------ ##
  pdf(paste0(figdir, "/summary_trueperformance", exts, dtpext, "_2.pdf"),
      width = 10, height = 7)
  
  fdrtpr <- fdrtpr %>% 
    tidyr::separate(method, c("method", "n_samples", "repl"), sep = "\\.") %>%
    dplyr::mutate(n_samples = factor(n_samples, levels = sort(unique(as.numeric(as.character(n_samples)))))) %>%
    dplyr::mutate(method = gsub(paste(exts, collapse = "|"), "", method))
  
  ## Set plot symbols for number of cells per group
  ncells <- sort(as.numeric(as.character(unique(fdrtpr$n_samples))))
  pch <- c(16, 17, 15, 3, 7, 8, 4, 6, 9, 10, 11, 12, 13, 14)[1:length(ncells)]
  names(pch) <- as.character(ncells)
  
  for (f in unique(fdrtpr$filt)) {
    for (asp in c("FDR", "TPR")) {
      p1 <- fdrtpr %>% dplyr::filter(filt == f) %>% dplyr::filter(thr == "thr0.05") %>%
        ggplot(aes_string(x = "method", y = asp, color = "method")) + 
        geom_boxplot(outlier.size = -1) + 
        geom_point(position = position_jitter(width = 0.2), size = 0.5, aes(shape = n_samples)) + 
        theme_bw() + xlab("") + ylab(paste0("True ", asp, " at adj.p = 0.05 cutoff")) + 
        scale_color_manual(values = cols) + 
        scale_shape_manual(values = pch) + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 12),
              axis.text.y = element_text(size = 12),
              axis.title.y = element_text(size = 13)) + 
        guides(color = guide_legend(ncol = 2, title = ""),
               shape = guide_legend(ncol = 2, title = "Number of \ncells per group")) + 
        ggtitle(f)
      if (asp == "FDR") p1 <- p1 + geom_hline(yintercept = 0.05)
      plots[[paste0(asp, "_all_", f)]] <- p1
      print(plots[[paste0(asp, "_all_", f)]])
    
      p3 <- fdrtpr %>% dplyr::filter(filt == f) %>% dplyr::filter(thr == "thr0.05") %>%
        dplyr::mutate(ncells = paste0(n_samples, " cells per group")) %>%
        dplyr::mutate(ncells = factor(ncells, levels = paste0(sort(unique(as.numeric(as.character(gsub(" cells per group", "", ncells))))), " cells per group"))) %>%
        ggplot(aes_string(x = "ncells", y = asp, color = "method", group = "method")) + 
        geom_point(alpha = 0.25) + geom_smooth(se = FALSE) + 
        facet_wrap(~dataset, scales = "free_x") + 
        theme_bw() + xlab("") + ylab(paste0("True ", asp, " at adj.p = 0.05 cutoff")) + 
        scale_color_manual(values = cols) + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 12),
              axis.text.y = element_text(size = 12),
              axis.title.y = element_text(size = 13)) + 
        guides(color = guide_legend(ncol = 2, title = ""),
               shape = guide_legend(ncol = 2, title = "Number of \ncells per group")) + 
        ggtitle(f)
      if (asp == "FDR") p3 <- p3 + geom_hline(yintercept = 0.05)
      plots[[paste0(asp, "_byncells_sep_", f)]] <- p3
      print(plots[[paste0(asp, "_byncells_sep_", f)]])
    }  
  }
  
  ## AUROC
  auroc <- auroc %>% 
    tidyr::separate(method, c("method", "n_samples", "repl"), sep = "\\.") %>%
    dplyr::mutate(n_samples = factor(n_samples, levels = sort(unique(as.numeric(as.character(n_samples)))))) %>%
    dplyr::mutate(method = gsub(paste(exts, collapse = "|"), "", method))

  asp <- "AUROC"
  for (f in unique(auroc$filt)) {
    plots[[paste0("auroc_all_", f)]] <- auroc %>%  dplyr::filter(filt == f) %>%
      ggplot(aes_string(x = "method", y = asp, color = "method")) + 
      geom_boxplot(outlier.size = -1) + 
      geom_point(position = position_jitter(width = 0.2), size = 0.5, aes(shape = n_samples)) + 
      theme_bw() + xlab("") + ylab("Area under ROC curve") + 
      scale_color_manual(values = cols) + 
      scale_shape_manual(values = pch) + 
      theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 12),
            axis.text.y = element_text(size = 12),
            axis.title.y = element_text(size = 13)) + 
      guides(color = guide_legend(ncol = 2, title = ""),
             shape = guide_legend(ncol = 1, title = "")) + 
      ggtitle(f)
    print(plots[[paste0("auroc_all_", f)]])
  
    plots[[paste0("auroc_byncells_sep_", f)]] <- auroc %>% dplyr::filter(filt == f) %>% 
      dplyr::mutate(ncells = paste0(n_samples, " cells per group")) %>%
      dplyr::mutate(ncells = factor(ncells, levels = paste0(sort(unique(as.numeric(as.character(gsub(" cells per group", "", ncells))))), " cells per group"))) %>%
      ggplot(aes_string(x = "ncells", y = asp, color = "method", group = "method")) + 
      geom_point(alpha = 0.25) + geom_smooth(se = FALSE) + 
      facet_wrap(~dataset, scales = "free_x") + 
      theme_bw() + xlab("") + ylab("Area under ROC curve") + 
      scale_color_manual(values = cols) + 
      theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 12),
            axis.text.y = element_text(size = 12),
            axis.title.y = element_text(size = 13)) + 
      guides(color = guide_legend(ncol = 2, title = "")) + 
      ggtitle(f)
    print(plots[[paste0("auroc_byncells_sep_", f)]])
  }
  
  dev.off()
  
  ## -------------------------- Final summary plots ------------------------- ##
  for (asp in c("FDR", "TPR", "auroc")) {
    pdf(paste0(figdir, "/true", asp, "_final", dtpext, ".pdf"), width = 12, height = 6)
    p <- plot_grid(plot_grid(plots[[paste0(asp, "_all_")]] + theme(legend.position = "none") + 
                               ggtitle("Without filtering") + ylim(-0.01, 1), 
                             plots[[paste0(asp, "_all_TPM_1_25p")]] + theme(legend.position = "none") + 
                               ggtitle("After filtering") + ylim(-0.01, 1),
                             labels = c("A", "B"), align = "h", rel_widths = c(1, 1), nrow = 1),
                   get_legend(plots[[paste0(asp, "_all_")]] + 
                                theme(legend.position = "bottom") + 
                                guides(colour = FALSE,
                                       shape = 
                                         guide_legend(nrow = 1,
                                                      title = "Number of cells per group",
                                                      override.aes = list(size = 1.5),
                                                      title.theme = element_text(size = 12,
                                                                                 angle = 0),
                                                      label.theme = element_text(size = 10,
                                                                                 angle = 0),
                                                      keywidth = 1, default.unit = "cm"))),
                   rel_heights = c(1.7, 0.1), ncol = 1)
    print(p)
    dev.off()
    
    pdf(paste0(figdir, "/true", asp, "_final_sepbyds", dtpext, ".pdf"), width = 12, height = 6)
    p <- plot_grid(plot_grid(plots[[paste0(asp, "_byncells_sep_")]] + theme(legend.position = "none") + 
                               ggtitle("Without filtering") + ylim(-0.01, 1), 
                             plots[[paste0(asp, "_byncells_sep_TPM_1_25p")]] + theme(legend.position = "none") + 
                               ggtitle("After filtering") + ylim(-0.01, 1),
                             labels = c("A", "B"), align = "h", rel_widths = c(1, 1), nrow = 1),
                   get_legend(plots[[paste0(asp, "_byncells_sep_")]] + 
                                theme(legend.position = "bottom") + 
                                guides(colour = 
                                         guide_legend(nrow = 3,
                                                      title = "",
                                                      override.aes = list(size = 1.5),
                                                      title.theme = element_text(size = 12,
                                                                                 angle = 0),
                                                      label.theme = element_text(size = 10,
                                                                                 angle = 0),
                                                      keywidth = 1, default.unit = "cm"))),
                   rel_heights = c(1.7, 0.3), ncol = 1)
    print(p)
    dev.off()
  }
}