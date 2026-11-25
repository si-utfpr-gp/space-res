// Comportamento dos protótipos. Não é código do sistema: só simula o suficiente para navegar entre as telas.
//
// Parâmetros da URL:
//   perfil=campus  mostra a tela como o administrador de campus vê (padrão: administrador geral)
//   notas=nao      esconde as notas do protótipo
//   estado=erros   mostra o formulário com erros de validação
//   aviso=<texto>  mostra um aviso, como o sistema faz depois de salvar
//
// Atributos usados nos HTML:
//   data-perfil="geral|campus"     só aparece para esse perfil
//   data-estado="normal|erros"     só aparece nesse estado
//   data-nota                      nota do protótipo (some com notas=nao)
//   data-nao-prototipada="texto"   link para uma tela fora dos protótipos: mostra o texto em vez de navegar
//   data-toast="texto"             botão que só mostra um aviso
//   data-filtro / data-filtro-*    filtros da listagem de espaços
(function () {
  const TELAS = [
    { arquivo: "admin.html", nome: "Entrada na área administrativa" },
    { arquivo: "campus.html", nome: "Página do campus" },
    { arquivo: "campus-espacos.html", nome: "Listagem: espaços do campus" },
    { arquivo: "campus-espaco-novo.html", nome: "Formulário: novo espaço" },
    { arquivo: "campus-administradores.html", nome: "Administradores do campus" }
  ];

  const params = new URLSearchParams(window.location.search);
  const state = {
    perfil: params.get("perfil") === "campus" ? "campus" : "geral",
    notas: params.get("notas") === "nao" ? "nao" : "sim",
    estado: params.get("estado") === "erros" ? "erros" : "normal"
  };
  const embedded = window.self !== window.top;
  const currentFile = window.location.pathname.split("/").pop() || "index.html";

  // Perfil e notas acompanham a navegação; o estado de erro vale só para a tela atual.
  function queryString(overrides) {
    const merged = Object.assign({}, state, { estado: "normal" }, overrides || {});
    const query = new URLSearchParams();
    if (merged.perfil !== "geral") query.set("perfil", merged.perfil);
    if (merged.notas !== "sim") query.set("notas", merged.notas);
    if (merged.estado !== "normal") query.set("estado", merged.estado);
    if (merged.aviso) query.set("aviso", merged.aviso);
    const text = query.toString();
    return text ? "?" + text : "";
  }

  // Usa o atributo hidden, que o preflight do Tailwind esconde mesmo com classes como flex no elemento.
  function applyVisibility() {
    document.querySelectorAll("[data-perfil], [data-estado], [data-nota]").forEach((element) => {
      const { perfil, estado } = element.dataset;
      element.hidden = Boolean((perfil && perfil !== state.perfil) ||
        (estado && estado !== state.estado) ||
        (element.hasAttribute("data-nota") && state.notas === "nao"));
    });
    // Campos com erro ficam com a borda vermelha, como no Form::Input::BaseComponent.
    document.querySelectorAll("[data-erro]").forEach((field) => {
      const invalid = state.estado === "erros";
      field.classList.toggle("border-red-500", invalid);
      field.classList.toggle("border-gray-300", !invalid);
      if (invalid) field.setAttribute("aria-invalid", "true");
    });
  }

  function propagateLinks() {
    document.querySelectorAll("a[href]").forEach((link) => {
      const href = link.getAttribute("href");
      if (/^[\w-]+\.html$/.test(href)) link.setAttribute("href", href + queryString());
    });
  }

  // Aviso no canto da tela, como o Flash::ToastMessageComponent do sistema.
  function showToast(message, tone) {
    let region = document.getElementById("prototype-toasts");
    if (!region) {
      region = document.createElement("div");
      region.id = "prototype-toasts";
      region.setAttribute("role", "status");
      region.setAttribute("aria-live", "polite");
      region.className = "pointer-events-none fixed inset-x-4 bottom-4 z-50 flex flex-col items-center gap-2 sm:inset-x-auto sm:right-4 sm:items-end";
      document.body.appendChild(region);
    }
    const toast = document.createElement("p");
    const colors = tone === "info" ? "border-amber-300 bg-amber-50 text-amber-900" : "border-green-300 bg-green-50 text-green-900";
    toast.className = "pointer-events-auto w-full max-w-sm rounded-lg border px-4 py-3 text-sm shadow-lg " + colors;
    toast.textContent = message;
    region.appendChild(toast);
    setTimeout(() => toast.remove(), 4500);
  }

  function setupNotPrototypedLinks() {
    document.querySelectorAll("[data-nao-prototipada]").forEach((element) => {
      element.addEventListener("click", (event) => {
        event.preventDefault();
        const detail = element.dataset.naoPrototipada;
        showToast("Fora dos protótipos." + (detail ? " " + detail : ""), "info");
      });
    });
    document.querySelectorAll("[data-toast]").forEach((element) => {
      element.addEventListener("click", (event) => {
        event.preventDefault();
        showToast(element.dataset.toast);
      });
    });
  }

  // Menu lateral no celular: abre por cima do conteúdo, como o ui--sidebar do sistema.
  function setupSidebar() {
    const button = document.querySelector("[data-menu-toggle]");
    const sidebar = document.querySelector("[data-sidebar]");
    const backdrop = document.querySelector("[data-backdrop]");
    if (!button || !sidebar) return;

    const setOpen = (open) => {
      sidebar.classList.toggle("-translate-x-full", !open);
      if (backdrop) backdrop.classList.toggle("hidden", !open);
      button.setAttribute("aria-expanded", String(open));
    };
    button.addEventListener("click", () => setOpen(sidebar.classList.contains("-translate-x-full")));
    if (backdrop) backdrop.addEventListener("click", () => setOpen(false));
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") setOpen(false);
    });
  }

  function setupDisclosures() {
    document.querySelectorAll("[data-disclosure]").forEach((button) => {
      const target = document.getElementById(button.getAttribute("aria-controls"));
      if (!target) return;
      button.addEventListener("click", (event) => {
        event.stopPropagation();
        const open = target.classList.contains("hidden");
        target.classList.toggle("hidden", !open);
        button.setAttribute("aria-expanded", String(open));
      });
      document.addEventListener("click", (event) => {
        if (!target.contains(event.target)) {
          target.classList.add("hidden");
          button.setAttribute("aria-expanded", "false");
        }
      });
    });
  }

  // Filtros da listagem: busca pelo nome e escolha de bloco e situação.
  function setupFilters() {
    const form = document.querySelector("[data-filtro]");
    if (!form) return;
    const rows = Array.from(document.querySelectorAll("[data-filtro-linha]"));
    const empty = document.querySelector("[data-filtro-vazio]");
    const counter = document.querySelector("[data-filtro-contagem]");
    const normalize = (text) => text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

    const apply = () => {
      const name = normalize(form.querySelector("[data-filtro-nome]").value.trim());
      const building = form.querySelector("[data-filtro-bloco]").value;
      const status = form.querySelector("[data-filtro-situacao]").value;
      let visible = 0;
      rows.forEach((row) => {
        const show = normalize(row.dataset.nome).includes(name) &&
          (!building || row.dataset.bloco === building) &&
          (!status || row.dataset.situacao === status);
        row.hidden = !show;
        if (show) visible += 1;
      });
      if (empty) empty.hidden = visible > 0;
      if (counter) counter.textContent = visible === rows.length
        ? rows.length + " espaços"
        : visible + " de " + rows.length + " espaços";
    };
    form.addEventListener("input", apply);
    form.addEventListener("change", apply);
    form.addEventListener("submit", (event) => event.preventDefault());
    apply();
  }

  // Salvar o formulário: sem erros, volta para a listagem com o aviso de sucesso.
  function setupForms() {
    document.querySelectorAll("form[data-salvar-para]").forEach((form) => {
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        if (state.estado === "erros") {
          showToast("No protótipo, os erros continuam. Use “Sem erros” na barra do protótipo.", "info");
          return;
        }
        window.location.href = form.dataset.salvarPara + queryString({ aviso: form.dataset.aviso });
      });
    });
  }

  function segmented(label, options, current, onPick) {
    const group = document.createElement("div");
    group.className = "flex items-center gap-1";
    group.setAttribute("role", "group");
    group.setAttribute("aria-label", label);
    const caption = document.createElement("span");
    caption.className = "font-semibold";
    caption.textContent = label + ":";
    group.appendChild(caption);
    options.forEach(([value, text]) => {
      const button = document.createElement("button");
      button.type = "button";
      const active = value === current;
      button.className = "rounded-full border px-2.5 py-1 " +
        (active ? "border-amber-700 bg-amber-700 text-white" : "border-amber-300 bg-white text-amber-900 hover:bg-amber-100");
      button.setAttribute("aria-pressed", String(active));
      button.textContent = text;
      button.addEventListener("click", () => onPick(value));
      group.appendChild(button);
    });
    return group;
  }

  // Barra do protótipo no topo de cada tela (some dentro da moldura de celular, que tem a própria).
  function buildToolbar() {
    if (embedded || !document.body.hasAttribute("data-tela")) return;

    const go = (overrides) => {
      window.location.href = currentFile + queryString(Object.assign({ estado: state.estado }, overrides));
    };
    const bar = document.createElement("div");
    bar.className = "flex flex-wrap items-center gap-x-4 gap-y-2 border-b border-amber-300 bg-amber-50 px-4 py-2 text-xs text-amber-900";
    bar.setAttribute("aria-label", "Barra do protótipo");

    const home = document.createElement("a");
    home.href = "index.html" + queryString();
    home.className = "text-xs font-semibold text-amber-900 underline";
    home.textContent = "Protótipo #89 · índice";
    bar.appendChild(home);

    bar.appendChild(segmented("Perfil", [ [ "geral", "Administrador geral" ], [ "campus", "Administrador de campus" ] ],
      state.perfil, (perfil) => go({ perfil })));
    bar.appendChild(segmented("Notas", [ [ "sim", "Mostrar" ], [ "nao", "Esconder" ] ],
      state.notas, (notas) => go({ notas })));
    if (document.body.hasAttribute("data-com-erros")) {
      bar.appendChild(segmented("Formulário", [ [ "normal", "Sem erros" ], [ "erros", "Com erros" ] ],
        state.estado, (estado) => go({ estado })));
    }

    const phone = document.createElement("a");
    phone.href = "celular.html" + queryString({ estado: state.estado }) +
      (queryString({ estado: state.estado }) ? "&" : "?") + "tela=" + encodeURIComponent(currentFile);
    phone.className = "text-xs font-semibold text-amber-900 underline";
    phone.textContent = "Ver no celular";
    bar.appendChild(phone);

    document.body.prepend(bar);
  }

  // Moldura de celular (celular.html): a tela escolhida dentro de um iframe com a largura do aparelho.
  function setupPhoneViewer() {
    const frame = document.querySelector("[data-celular-frame]");
    if (!frame) return;
    const screenSelect = document.querySelector("[data-celular-tela]");
    const widthSelect = document.querySelector("[data-celular-largura]");
    const toolbar = document.querySelector("[data-celular-barra]");
    const fullLink = document.querySelector("[data-celular-tela-grande]");

    let screen = params.get("tela");
    if (!TELAS.some((tela) => tela.arquivo === screen)) screen = TELAS[0].arquivo;
    const width = [ "320", "360", "390" ].includes(params.get("largura")) ? params.get("largura") : "360";

    TELAS.forEach((tela) => screenSelect.add(new Option(tela.nome, tela.arquivo, false, tela.arquivo === screen)));
    widthSelect.value = width;

    const reload = (overrides) => {
      const next = Object.assign({ tela: screenSelect.value, largura: widthSelect.value }, overrides);
      const base = queryString({ estado: state.estado, perfil: next.perfil || state.perfil, notas: next.notas || state.notas });
      window.location.href = "celular.html" + base + (base ? "&" : "?") +
        "tela=" + encodeURIComponent(next.tela) + "&largura=" + next.largura;
    };
    screenSelect.addEventListener("change", () => reload());
    widthSelect.addEventListener("change", () => reload());
    toolbar.appendChild(segmented("Perfil", [ [ "geral", "Administrador geral" ], [ "campus", "Administrador de campus" ] ],
      state.perfil, (perfil) => reload({ perfil })));
    toolbar.appendChild(segmented("Notas", [ [ "sim", "Mostrar" ], [ "nao", "Esconder" ] ],
      state.notas, (notas) => reload({ notas })));

    frame.style.width = width + "px";
    frame.src = screen + queryString({ estado: state.estado });
    fullLink.href = screen + queryString({ estado: state.estado });
  }

  function setupNotice() {
    const notice = params.get("aviso");
    if (notice) showToast(notice);
  }

  document.addEventListener("DOMContentLoaded", () => {
    applyVisibility();
    propagateLinks();
    setupNotPrototypedLinks();
    setupSidebar();
    setupDisclosures();
    setupFilters();
    setupForms();
    buildToolbar();
    setupPhoneViewer();
    setupNotice();
  });
})();
