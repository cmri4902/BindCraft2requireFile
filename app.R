# BindCraft2 Lab Viewer — R Shiny demonstration
# DEMO mode (default): only bundled synthetic examples; safe for a PUBLIC hosting trial.
# LAB mode: enables file uploads. This code provides NO authentication on its own.
# NOTE: Does not run BindCraft2, SLURM, or any GPU computations.

library(shiny)
library(r3dmol)

options(shiny.maxRequestSize = 15 * 1024^2)
lab_mode <- identical(tolower(Sys.getenv("APP_MODE", "demo")), "lab")

base_dir <- getwd()
demo <- read.csv(file.path(base_dir, "data", "demo_ranking.csv"), stringsAsFactors = FALSE)
required_files <- file.path(base_dir, "data", demo$structure_file)
stopifnot(all(file.exists(required_files)))

score_value <- function(row, name, digits = 2L) {
  if (is.null(row) || nrow(row) == 0L || !(name %in% names(row))) return("—")
  value <- suppressWarnings(as.numeric(row[[name]][1]))
  if (is.na(value)) "—" else sprintf(paste0("%.", digits, "f"), value)
}

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$style(HTML("\n      body { background:#f4f7fb; color:#203047; font-family: 'Segoe UI', Arial, sans-serif; }\n      .container-fluid {max-width:1440px;padding-left:30px;padding-right:30px;}\n      .topbar {display:flex;justify-content:space-between;align-items:center;margin:27px 0 22px;gap:14px;flex-wrap:wrap;}\n      .brand {font-size:25px;font-weight:750;letter-spacing:-.5px;color:#15253e;}\n      .brand span {color:#137c92;}\n      .modepill {display:inline-block;padding:7px 13px;border-radius:30px;background:#e7f5f2;color:#11705f;font-size:12px;font-weight:800;letter-spacing:1px;}\n      .intro {margin-bottom:19px;color:#687a90;max-width:850px;line-height:1.5;}\n      .card {background:#fff;border:1px solid #e5ecf2;border-radius:16px;padding:22px;box-shadow:0 3px 19px rgba(26,53,93,.045);margin-bottom:18px;}\n      .card h3 {margin:0 0 18px;font-size:16px;font-weight:750;color:#263e58;}\n      .side-label {color:#708397;font-size:11px;font-weight:700;letter-spacing:1.1px;margin-bottom:13px;}\n      .metric-row {display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px;margin-bottom:18px;}\n      .metric {background:white;border-radius:15px;padding:16px 20px;border:1px solid #e4eaf0;}\n      .metric-label {text-transform:uppercase;letter-spacing:1px;font-size:10px;font-weight:800;color:#8091a5;}\n      .metric-value {font-size:29px;line-height:1.5;font-weight:750;color:#173d52;}\n      .metric-help {font-size:11px;color:#8293a1;}\n      .viewer-head {display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:10px;}\n      .viewer-head h3 {margin:0;}\n      .viewer-tag {font-size:11px;background:#edf5fb;padding:6px 10px;color:#4e7293;border-radius:40px;}\n      #structure_view {border-radius:12px;overflow:hidden;background:#f7fafc;min-height:440px;}\n      .legend-row {font-size:12px;color:#627991;margin-top:15px;}\n      .dot {display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:6px;}\n      .dot-a {background:#347b98;} .dot-b {background:#c67584;}\n      .banner {background:#fff9e9;border:1px solid #f0e3b9;color:#866722;padding:11px 14px;border-radius:10px;margin:13px 0 18px;font-size:12px;}\n      .info-note {font-size:12px;color:#8190a1;line-height:1.6;margin-top:11px;}\n      .btn {border-radius:8px;} .btn-primary {background:#14768b;border-color:#14768b;}\n      .form-control {border-color:#dce5ed;border-radius:8px;} label {color:#354b61;font-size:12px;font-weight:700;}\n      .table>thead>tr>th {background:#f6f9fc;color:#54687e;font-size:11px;}\n      .table>tbody>tr>td {color:#495d72;font-size:12px;white-space:nowrap;}\n      .table-responsive {overflow-x:auto;}\n      .footer {color:#8b9bac;font-size:11px;margin:15px 0 33px;}\n      @media(max-width:900px){.container-fluid{padding-left:15px;padding-right:15px}.metric-row{grid-template-columns:repeat(2,minmax(0,1fr))}}\n    "))
  ),
  div(class = "topbar",
      div(class = "brand", "BindCraft", tags$span("2"), " / Lab Viewer"),
      div(class = "modepill", if (lab_mode) "LAB MODE · UPLOADS ON" else "PUBLIC DEMO · SYNTHETIC DATA")
  ),
  div(class = "intro", "Explore protein complexes, compare candidate scores, and export structures. This is a standalone visualization demo; no HPC connection or protein design is performed."),
  div(class = "banner", tags$strong("Illustrative data only. "),
      "The bundled structures and confidence scores are synthetic examples, not BindCraft2 predictions, binding affinities, or lab results."),
  fluidRow(
    column(width = 3,
      div(class = "card",
          div(class = "side-label", "VIEWER CONTROLS"),
          selectInput("candidate", "Select candidate", choices = stats::setNames(demo$design, demo$label), selected = "DEMO_A"),
          selectInput("view_style", "Structure style", choices = c("Cartoon" = "cartoon", "Sticks" = "stick", "Lines" = "line"), selected = "cartoon"),
          selectInput("color_mode", "Coloring", choices = c("By chain" = "chain", "Rainbow by sequence" = "spectrum"), selected = "chain"),
          if (lab_mode) tagList(
             tags$hr(),
             div(class = "side-label", "PRIVATE LAB FILES"),
             fileInput("structure_upload", "Upload PDB or CIF", accept = c(".pdb", ".cif")),
             fileInput("ranking_upload", "Upload ranking CSV (optional)", accept = ".csv"),
             p(class = "info-note", "Uploads are only appropriate on authenticated, institution-approved deployments. The uploaded structure is displayed independently of any ranking CSV.")
          ) else p(class = "info-note", "Public demo disables uploads. For private lab deployment, set APP_MODE=lab and protect the app with institutional authentication."),
          tags$hr(),
          downloadButton("download_structure", "Download structure", class = "btn-primary"),
          tags$div(style = "height:10px;"),
          downloadButton("download_ranking", "Download ranking CSV")
      ),
      div(class = "card",
          h3("About this test"),
          tags$p(class = "info-note", "A reproducible R Shiny + r3dmol UI test using built-in sample files. You can publish the demo to a public hosting service to verify external accessibility.")
      )
    ),
    column(width = 9,
      div(class = "metric-row",
          div(class = "metric", div(class = "metric-label", "i_pDAE"), div(class = "metric-value", textOutput("metric_pdae", inline = TRUE)), div(class = "metric-help", "Interface confidence*")),
          div(class = "metric", div(class = "metric-label", "i_pTM"), div(class = "metric-value", textOutput("metric_ptm", inline = TRUE)), div(class = "metric-help", "Interface confidence*")),
          div(class = "metric", div(class = "metric-label", "pLDDT"), div(class = "metric-value", textOutput("metric_plddt", inline = TRUE)), div(class = "metric-help", "Predicted local confidence*")),
          div(class = "metric", div(class = "metric-label", "i_pAE"), div(class = "metric-value", textOutput("metric_pae", inline = TRUE)), div(class = "metric-help", "Interface error*"))
      ),
      div(class = "card",
          div(class = "viewer-head", h3("Interactive 3D Complex"), span(class = "viewer-tag", textOutput("file_source", inline = TRUE))),
          r3dmolOutput("structure_view", height = "480px"),
          div(class = "legend-row", span(class = "dot dot-a"), "Chain A · target    ", span(class = "dot dot-b", style = "margin-left:22px;"), "Chain B · illustrative binder"),
          p(class = "info-note", "Rotate: drag. Zoom: scroll. *Scores displayed above are mock values and do not describe the synthetic coordinates.")
      ),
      div(class = "card",
          div(class = "viewer-head", h3("Candidate Ranking"), span(class = "viewer-tag", "Example CSV / uploaded CSV")),
          div(class = "table-responsive", tableOutput("rank_table")),
          p(class = "info-note", "Public demonstration uses mock numbers. In lab mode, uploaded rankings display as a separate table and are not automatically matched with uploaded structures.")
      )
    )
  ),
  div(class = "footer", "BindCraft2 Lab Viewer prototype · Visualization only · No login, SLURM submission, GPU inference, or biological validation built in")
)

server <- function(input, output, session) {
  ranking <- reactive({
    if (lab_mode && !is.null(input$ranking_upload)) {
      d <- tryCatch(read.csv(input$ranking_upload$datapath, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
      validate(need(!is.null(d) && nrow(d) > 0, "Ranking CSV could not be read or is empty."))
      return(d)
    }
    demo
  })

  current <- reactive({
    row <- demo[demo$design == input$candidate, , drop = FALSE]
    validate(need(nrow(row) == 1L, "Select a demo candidate."))
    row
  })

  custom_structure <- reactive({lab_mode && !is.null(input$structure_upload)})

  structure_source <- reactive({
    if (custom_structure()) {
      filename <- input$structure_upload$name
      ext <- tolower(tools::file_ext(filename))
      validate(need(ext %in% c("pdb", "cif"), "Only .pdb or .cif files are supported."))
      return(list(path = input$structure_upload$datapath, type = ext, filename = filename))
    }
    row <- current()
    nm <- row$structure_file[1]
    list(path = file.path(base_dir, "data", nm), type = "pdb", filename = nm)
  })

  metric <- function(col, digits = 2L) {
    if (custom_structure()) return("—")
    score_value(current(), col, digits)
  }
  output$metric_pdae <- renderText(metric("i_pDAE"))
  output$metric_ptm <- renderText(metric("i_pTM"))
  output$metric_plddt <- renderText(metric("pLDDT", 1L))
  output$metric_pae <- renderText(metric("i_pAE"))
  output$file_source <- renderText(if (custom_structure()) "Uploaded file" else "Bundled PDB")

  output$structure_view <- renderR3dmol({
    f <- structure_source()
    validate(need(file.exists(f$path), "Structure file is missing."))
    viewer <- r3dmol() |>
      m_add_model(data = f$path, format = f$type)

    style_fn <- switch(input$view_style,
      "stick" = function(clr) m_style_stick(color = clr, radius = 0.22),
      "line" = function(clr) m_style_line(color = clr),
      function(clr) m_style_cartoon(color = clr)
    )
    viewer <- viewer |> m_set_style(style = style_fn("#8898a8"))
    if (identical(input$color_mode, "chain")) {
      viewer <- viewer |>
        m_set_style(sel = m_sel(chain = "A"), style = style_fn("#347b98")) |>
        m_set_style(sel = m_sel(chain = "B"), style = style_fn("#c67584"))
    } else if (identical(input$view_style, "cartoon")) {
      viewer <- viewer |> m_set_style(style = m_style_cartoon(color = "spectrum"))
    }
    viewer |> m_zoom_to()
  })

  output$rank_table <- renderTable({
    d <- ranking()
    visible <- intersect(c("design", "i_pDAE", "i_pTM", "pLDDT", "i_pAE", "Interface_Residues", "Binder_Sequence", "failed_filters"), names(d))
    if (length(visible) == 0L) visible <- head(names(d), 7)
    utils::head(d[, visible, drop = FALSE], 15)
  }, striped = TRUE, hover = TRUE, spacing = "s", rownames = FALSE, sanitize.text.function = htmltools::htmlEscape)

  output$download_structure <- downloadHandler(
    filename = function() structure_source()$filename,
    content = function(file) file.copy(structure_source()$path, file, overwrite = TRUE)
  )
  output$download_ranking <- downloadHandler(
    filename = function() if (lab_mode && !is.null(input$ranking_upload)) "lab_uploaded_ranking.csv" else "demo_ranking_MOCK.csv",
    content = function(file) utils::write.csv(ranking(), file, row.names = FALSE, na = "")
  )
}

shinyApp(ui = ui, server = server)
