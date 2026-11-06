// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRestore => 'Restaurar';

  @override
  String get commonShare => 'Compartilhar';

  @override
  String get commonGotIt => 'Entendi';

  @override
  String commonError(String error) {
    return 'Erro: $error';
  }

  @override
  String get settingsTitle => 'Configurações';

  @override
  String settingsSubtitle(String version) {
    return 'Inklus $version · suas notas ficam neste dispositivo';
  }

  @override
  String get settingsSectionDrive => 'Google Drive';

  @override
  String get settingsSectionAppearance => 'Aparência';

  @override
  String get settingsSectionFiles => 'Backups e arquivos';

  @override
  String get settingsSectionTools => 'Ferramentas';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsImportTitle => 'Importar .inklus ou backup';

  @override
  String get settingsImportSubtitle =>
      'Um caderno (.inklus) ou um backup completo (.zip); detectado automaticamente';

  @override
  String get settingsExportTitle => 'Exportar backup completo';

  @override
  String get settingsExportSubtitle =>
      'Todos os cadernos, imagens e lixeira em um único .zip';

  @override
  String get settingsAutosaveTitle => 'Salvamento automático';

  @override
  String get settingsAutosaveSubtitle =>
      'Cada alteração é salva na hora neste dispositivo. Uma versão é guardada cada vez que você abre e fecha uma nota (menu ⋮ → Histórico de versões).';

  @override
  String get settingsStatsTitle => 'Estatísticas de escrita';

  @override
  String get settingsStatsSubtitle => 'Traços, páginas, sequências e atividade';

  @override
  String get settingsRemindersTitle => 'Lembretes';

  @override
  String get settingsRemindersSubtitle => 'Avisos ligados aos seus cadernos';

  @override
  String get settingsTrashTitle => 'Lixeira';

  @override
  String get settingsTrashSubtitle => 'Recupere cadernos e notas excluídos';

  @override
  String get settingsAppTagline => 'Escrita à mão para tablets com caneta';

  @override
  String get settingsFreeTitle => 'Livre e aberto';

  @override
  String get settingsFreeSubtitle =>
      'Código aberto (GPL-3.0). Sem recursos pagos, sem anúncios e sem análises.';

  @override
  String get settingsPrivacyTitle => 'Política de privacidade';

  @override
  String get settingsPrivacySubtitle =>
      'Quais dados o app trata e para onde vão';

  @override
  String get settingsSourceTitle => 'Código-fonte';

  @override
  String get settingsSourceSubtitle =>
      'Relate um bug ou sugira melhorias no GitHub';

  @override
  String get settingsErrorLogTitle => 'Registro de erros';

  @override
  String get settingsErrorLogSubtitle =>
      'Fica só neste dispositivo; você pode compartilhá-lo para ajudar a corrigir um bug';

  @override
  String get settingsErrorLogEmpty => 'Nenhum erro registrado';

  @override
  String settingsErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erros registrados',
      one: '1 erro registrado',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorLogShareSubtitle =>
      'Por e-mail ou em uma issue do GitHub';

  @override
  String get settingsErrorLogClear => 'Limpar registro';

  @override
  String get settingsErrorLogCleared => 'Registro limpo';

  @override
  String settingsErrorLogSubject(String version) {
    return 'Registro de erros do Inklus $version';
  }

  @override
  String settingsOpenFailed(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLowPowerTitle => 'Modo economia';

  @override
  String get settingsLowPowerSubtitle =>
      'Usa menos memória em tablets e celulares modestos: imagens mais leves. Vale ao abrir a próxima nota.';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get driveConnected => 'Conectado';

  @override
  String get driveCloudCopy => 'Backup na nuvem';

  @override
  String get driveGoogleAccount => 'Conta do Google';

  @override
  String get driveOptionalPitch =>
      'Opcional: guarde uma cópia das suas notas no seu Google Drive';

  @override
  String get driveConnect => 'Conectar';

  @override
  String get driveUploadNow => 'Enviar agora';

  @override
  String get driveUploadNowSubtitle =>
      'Envia as notas dos cadernos com sincronização ativada';

  @override
  String get driveRestore => 'Restaurar do Drive';

  @override
  String get driveRestoreSubtitle =>
      'Traz as versões mais recentes e recupera notas que faltam neste dispositivo';

  @override
  String get driveNoteVersions => 'Versões de uma nota';

  @override
  String get driveNoteVersionsSubtitle => 'No editor: ⋮ → Histórico de versões';

  @override
  String get driveSwitchAccount => 'Trocar de conta';

  @override
  String get driveSignOut => 'Sair';

  @override
  String get driveAccount => 'Conta';

  @override
  String driveConnectedAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get driveNotConfigured => 'O Google não está configurado';

  @override
  String get driveSignOutQuestion => 'Sair?';

  @override
  String get driveSignOutBody =>
      'Os backups deixarão de ser enviados ao Google Drive. As cópias que já estão no Drive são mantidas.';

  @override
  String get driveSignedOut => 'Sessão encerrada';

  @override
  String driveUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas enviadas ao Drive',
      one: '1 nota enviada ao Drive',
      zero: 'Nenhum caderno tem a sincronização ativada',
    );
    return '$_temp0';
  }

  @override
  String get driveRestoreBody =>
      'As notas deste dispositivo só são substituídas se a cópia do Drive for mais recente. As notas que faltam aqui voltam ao seu caderno (ou a um novo caderno “Recuperado do Drive”).';

  @override
  String get backupSaveTitle => 'Salvar backup do Inklus';

  @override
  String get backupSaved => 'Backup salvo';

  @override
  String get driveSignInIncomplete => 'O login não foi concluído';

  @override
  String get driveDetails => 'Detalhes';

  @override
  String get driveSignInHelpTitle => 'Não foi possível entrar';

  @override
  String driveSignInHelpBody(String details) {
    return 'Se você acabou de fechar o seletor de contas, não há nenhum problema. Se escolheu uma conta e ela não conectou, quase sempre é porque a chave de assinatura do app (SHA-1) não está registrada no Google Cloud para com.inklus.inklus.\n\nDetalhe técnico:\n$details';
  }

  @override
  String get driveNotebooksTitle => 'Cadernos que sincronizam';

  @override
  String get driveNotebooksSubtitle =>
      'Cada caderno é salvo no Drive → Inklus → sua própria pasta. Escolha quais.';

  @override
  String get driveNotebooksEmpty => 'Ainda não há cadernos.';

  @override
  String get driveSyncMenu => 'Sincronizar com o Drive';

  @override
  String get driveSyncEnabled => 'Sincronização ativada';

  @override
  String get driveSyncDisabled => 'Sincronização desativada';

  @override
  String get textEditHint => 'Escreva aqui…';

  @override
  String get textEditMove => 'Mover caixa';

  @override
  String get textEditWidth => 'Largura da caixa';

  @override
  String get textEditSmaller => 'Menor';

  @override
  String get textEditLarger => 'Maior';

  @override
  String get textEditBold => 'Negrito';

  @override
  String get textEditItalic => 'Itálico';

  @override
  String get textEditUnderline => 'Sublinhado';

  @override
  String get textEditStrike => 'Tachado';

  @override
  String get textEditColor => 'Cor do texto';

  @override
  String get textEditHighlight => 'Realce';

  @override
  String get textEditAlign => 'Alinhamento';

  @override
  String get textEditSpacing => 'Espaçamento entre linhas';

  @override
  String get textEditLinkActive => 'Link para página (ativo)';

  @override
  String get textEditLink => 'Link para página';

  @override
  String get textEditDelete => 'Excluir caixa';

  @override
  String get textEditDone => 'Concluído';

  @override
  String get textEditWholeBox => 'Caixa inteira';

  @override
  String get textEditNoHighlight => 'Sem realce';

  @override
  String get textEditUnlink => 'Remover link';

  @override
  String commonPageN(int n) {
    return 'Página $n';
  }

  @override
  String get marketWhereTemplate => 'no menu Modelo da página';

  @override
  String get marketWherePalette => 'nas cores de cada caneta';

  @override
  String get marketWhereStickers => 'em Mais ferramentas → Inserir adesivo';

  @override
  String get marketHeroTitle => 'Descubra e personalize';

  @override
  String get marketHeroSubtitle =>
      'Modelos, paletas e adesivos da comunidade. Gratuitos e com licença aberta.';

  @override
  String get marketSearch => 'Buscar pacotes';

  @override
  String get marketTitle => 'Marketplace';

  @override
  String get marketOfflineCache =>
      'Offline: mostrando o último catálogo baixado';

  @override
  String get marketOfflineBundled =>
      'Offline: mostrando os pacotes incluídos no app';

  @override
  String get marketAll => 'Todos';

  @override
  String get marketTemplates => 'Modelos';

  @override
  String get marketPalettes => 'Paletas';

  @override
  String get marketStickers => 'Adesivos';

  @override
  String get marketPalette => 'Paleta';

  @override
  String get marketNoResults => 'Nenhum pacote encontrado';

  @override
  String get marketRemove => 'Remover';

  @override
  String get marketInstall => 'Instalar';

  @override
  String marketUninstalled(String name) {
    return '“$name” desinstalado';
  }

  @override
  String marketInstalled(String name, String where) {
    return '“$name” instalado: $where';
  }

  @override
  String marketInstallFailed(String name, String error) {
    return 'Não foi possível instalar “$name”: $error';
  }

  @override
  String get createTplBlank => 'Em branco';

  @override
  String get createTplRuled => 'Pautado';

  @override
  String get createTplGrid => 'Quadriculado';

  @override
  String get createTplDots => 'Pontilhado';

  @override
  String get createTplMusic => 'Pentagrama';

  @override
  String get createTplPlanner => 'Agenda';

  @override
  String get createTplHabit => 'Hábitos';

  @override
  String get createTplCornell => 'Cornell';

  @override
  String get createTplWeekly => 'Semana';

  @override
  String get createTplMonthly => 'Mês';

  @override
  String get createTplTodo => 'Tarefas';

  @override
  String get createTplStoryboard => 'Storyboard';

  @override
  String get createTplMillimeter => 'Milimetrado';

  @override
  String get createTplSheet => 'Folha A4';

  @override
  String get createTitle => 'Novo caderno';

  @override
  String get createName => 'Nome';

  @override
  String get createNameHint => 'Meu caderno';

  @override
  String get createCover => 'Capa';

  @override
  String get createDesign => 'Design';

  @override
  String get createYourImage => 'Sua imagem';

  @override
  String get createChangeImage => 'Trocar imagem';

  @override
  String get createColor => 'Cor';

  @override
  String get createNext => 'Próximo';

  @override
  String get createStep2 => 'Passo 2: escolha um modelo';

  @override
  String get createBackToStep1 => 'Voltar ao passo 1';

  @override
  String get createTemplate => 'Modelo';

  @override
  String get createMoreTemplates => 'Mostrar mais modelos';

  @override
  String get createFewer => 'Mostrar menos';

  @override
  String get createInfinite => 'Tela infinita';

  @override
  String get createInfiniteOn => 'A tela cresce conforme você escreve';

  @override
  String get createInfiniteOff => 'Folha de tamanho fixo (A4)';

  @override
  String get createAction => 'Criar caderno';

  @override
  String createDefaultName(int n) {
    return 'Caderno $n';
  }

  @override
  String createCoverSemantics(String name) {
    return 'Capa $name';
  }

  @override
  String get libRenameTitle => 'Renomear caderno';

  @override
  String get libDeleteTitle => 'Excluir caderno';

  @override
  String get libDelete => 'Excluir';

  @override
  String get libCoverColor => 'Cor da capa';

  @override
  String get commonSave => 'Salvar';

  @override
  String get libSortTitle => 'Ordenar cadernos';

  @override
  String get libSortNewestFirst => 'Mais recentes primeiro';

  @override
  String get libSortOldestFirst => 'Mais antigos primeiro';

  @override
  String get libSortTitleAZ => 'Título A → Z';

  @override
  String get libSortTitleZA => 'Título Z → A';

  @override
  String get libNavAll => 'Todos';

  @override
  String get libNavRecent => 'Recentes';

  @override
  String get libNavFavorites => 'Favoritos';

  @override
  String get libNavFolders => 'Pastas';

  @override
  String get libImport => 'Importar .inklus';

  @override
  String get libTrash => 'Lixeira';

  @override
  String get libLightMode => 'Modo claro';

  @override
  String get libDarkMode => 'Modo escuro';

  @override
  String get libMoreOptions => 'Mais opções';

  @override
  String get libMyNotebooks => 'Meus cadernos';

  @override
  String get libClearFilter => 'Limpar filtro';

  @override
  String get libSearchHint => 'Buscar por nome ou etiqueta';

  @override
  String get libSearchInNotes =>
      'Buscar dentro das notas (texto e escrita à mão)';

  @override
  String get libSearchContent => 'No conteúdo';

  @override
  String get libSortNewest => 'Mais recentes';

  @override
  String get libSortOldest => 'Mais antigos';

  @override
  String get libSortNameAZ => 'Nome A–Z';

  @override
  String get libSortNameZA => 'Nome Z–A';

  @override
  String get libGrid => 'Grade';

  @override
  String get libList => 'Lista';

  @override
  String get libNoResults => 'Nenhum caderno encontrado';

  @override
  String get libEmptyTitle => 'Comece a escrever';

  @override
  String get libNoResultsHint => 'Tente outro nome ou etiqueta.';

  @override
  String get libUnfavorite => 'Remover dos favoritos';

  @override
  String get libFavorite => 'Adicionar aos favoritos';

  @override
  String get libRename => 'Renomear';

  @override
  String get libDuplicate => 'Duplicar';

  @override
  String get libCoverAndColor => 'Capa e cor';

  @override
  String get libTags => 'Etiquetas';

  @override
  String get libSyncOff => 'Parar de sincronizar com o Drive';

  @override
  String get libMoveToTrash => 'Mover para a lixeira';

  @override
  String get libNotebookOptions => 'Opções do caderno';

  @override
  String libSyncWillSync(String title) {
    return '“$title” será sincronizado com o Drive';
  }

  @override
  String libSyncStopped(String title) {
    return '“$title” não será mais sincronizado';
  }

  @override
  String libDeleteBody(String title) {
    return '\"$title\" será movido para a lixeira. Você pode restaurá-lo de lá.';
  }

  @override
  String libImportError(String error) {
    return 'Erro ao importar: $error';
  }

  @override
  String libCountAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total cadernos',
      one: '1 caderno',
    );
    return '$_temp0';
  }

  @override
  String libCountOf(int shown, int total) {
    return '$shown de $total cadernos';
  }

  @override
  String libNotebookSemantics(String title, String when) {
    return 'Caderno $title, $when';
  }

  @override
  String get libEmptyHint =>
      'Crie um novo caderno ou importe um existente\\npara começar.';

  @override
  String get noteRenameTitle => 'Renomear nota';

  @override
  String get noteDeleteTitle => 'Excluir nota';

  @override
  String get noteNew => 'Nova nota';

  @override
  String get noteNameHint => 'Minha nota';

  @override
  String get noteCreate => 'Criar';

  @override
  String get noteEmptyTitle => 'Nenhuma nota';

  @override
  String get noteEmptyHint => 'Crie sua primeira nota para começar a escrever.';

  @override
  String get noteCreateAction => 'Criar nota';

  @override
  String get noteOptions => 'Opções';

  @override
  String get timeNow => 'agora mesmo';

  @override
  String get noteTplInfinite => 'Infinita';

  @override
  String get noteTplSheet => 'Folha fixa';

  @override
  String get noteTplPlanner => 'Agenda';

  @override
  String get tplInfiniteHint => 'As infinitas crescem conforme você escreve';

  @override
  String get tplNormalSheet => 'Folha comum';

  @override
  String get tplOwn => 'Seu próprio modelo';

  @override
  String get tplFromMarket => 'Do marketplace';

  @override
  String get tplMine => 'Meus modelos';

  @override
  String get tplSaveCurrent => 'Salvar o atual';

  @override
  String get tplCustomize => 'Personalizar';

  @override
  String get tplLineColor => 'Cor das linhas';

  @override
  String get tplSpacing => 'Espaçamento';

  @override
  String get tplFixedSheet => 'Folha de tamanho fixo';

  @override
  String get tplSheetSize => 'Tamanho da folha';

  @override
  String get tplLetter => 'Carta';

  @override
  String get tplHowTitle => 'Como o modelo deve ser usado?';

  @override
  String get tplHowBody => 'A imagem será usada como fundo para escrever.';

  @override
  String get tplAsSheet => 'Como folha fixa';

  @override
  String get tplAsFill => 'Preenchimento infinito';

  @override
  String get tplOnlyImage => 'Só é possível salvar modelos com imagem';

  @override
  String get tplSaveTitle => 'Salvar modelo';

  @override
  String get tplDefaultName => 'Meu modelo';

  @override
  String get tplSaved => 'Modelo salvo';

  @override
  String get tplDeleteTitle => 'Excluir modelo';

  @override
  String get tplDeleteBody => 'Excluir este modelo salvo?';

  @override
  String get colorCustomTitle => 'Cor personalizada';

  @override
  String get colorCurrent => 'Atual';

  @override
  String get colorNew => 'Nova';

  @override
  String get colorWheel => 'Roda';

  @override
  String get colorHue => 'Matiz';

  @override
  String get colorSaturation => 'Saturação';

  @override
  String get colorBrightness => 'Brilho';

  @override
  String get colorUse => 'Usar';

  @override
  String timeMinAgo(int n) {
    return 'há $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'há $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'há $n d';
  }

  @override
  String get timeDeletedNow => 'excluído agora mesmo';

  @override
  String timeDeletedMin(int n) {
    return 'excluído há $n min';
  }

  @override
  String timeDeletedHours(int n) {
    return 'excluído há $n h';
  }

  @override
  String timeDeletedDays(int n) {
    return 'excluído há $n dias';
  }

  @override
  String timeDeletedOn(String date) {
    return 'excluído em $date';
  }

  @override
  String noteDeleteBody(String title) {
    return '\"$title\" será removida deste caderno.';
  }

  @override
  String noteDefaultName(int n) {
    return 'Nota $n';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String notePageCount(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0 · $when';
  }

  @override
  String tplImageLoadFailed(String error) {
    return 'Não foi possível carregar a imagem: $error';
  }

  @override
  String tplSaveFailed(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get colorSliders => 'Controles';

  @override
  String get selPaste => 'Colar';

  @override
  String get selCopy => 'Copiar';

  @override
  String get selCopied => 'Copiado';

  @override
  String get selThinner => 'Mais fino';

  @override
  String get selThicker => 'Mais grosso';

  @override
  String get selToText => 'Converter em texto';

  @override
  String get selDeselect => 'Desmarcar';

  @override
  String get selNoText => 'Nenhum texto reconhecido na seleção';

  @override
  String get selConvert => 'Converter';

  @override
  String get popPenType => 'Tipo de caneta';

  @override
  String get popThickness => 'Espessura';

  @override
  String get popStraighten => 'Endireitar formas';

  @override
  String get popNo => 'Não';

  @override
  String get popOnHold => 'Ao segurar';

  @override
  String get popAlways => 'Sempre';

  @override
  String get popShapeOffHint => 'Os traços ficam como foram feitos.';

  @override
  String get popShapeHoldHint =>
      'Segure a caneta parada por quase um segundo ao terminar uma linha, círculo, triângulo ou retângulo.';

  @override
  String get popShapeAlwaysHint =>
      'Toda forma reconhecível é endireitada ao levantar a caneta.';

  @override
  String get popAdvanced => 'Ajustes avançados do traço';

  @override
  String get popMode => 'Modo';

  @override
  String get popPartial => 'Parcial';

  @override
  String get popStroke => 'Traço';

  @override
  String get popHighlighter => 'Marca-texto';

  @override
  String get popEraseOff => 'Apaga só o que você toca, como uma borracha.';

  @override
  String get popEraseStroke => 'Apaga o traço inteiro ao tocá-lo.';

  @override
  String get popEraseHighlighter =>
      'Só apaga o marca-texto; a tinta não é afetada.';

  @override
  String get popSize => 'Tamanho';

  @override
  String get tbBackToLibrary => 'Voltar à biblioteca';

  @override
  String get tbHidePages => 'Ocultar páginas';

  @override
  String get tbPages => 'Páginas';

  @override
  String get tbHideLayers => 'Ocultar camadas';

  @override
  String get tbLayers => 'Camadas';

  @override
  String get tbInsertImage => 'Inserir imagem';

  @override
  String get tbRuler => 'Régua';

  @override
  String get tbRulerNext => 'Régua (toque: transferidor)';

  @override
  String get tbProtractorNext => 'Transferidor (toque: ocultar)';

  @override
  String get tbMoveSelect => 'Mover / selecionar imagens e traços';

  @override
  String get tbFill => 'Preencher área';

  @override
  String get tbHideMagnifier => 'Ocultar lupa';

  @override
  String get tbMagnifier => 'Lupa';

  @override
  String get tbLaserOff => 'Desligar apontador laser';

  @override
  String get tbLaser => 'Apontador laser';

  @override
  String get tbInsertSticker => 'Inserir adesivo';

  @override
  String get tbPageTemplate => 'Modelo da página';

  @override
  String get tbMoreTools => 'Mais ferramentas';

  @override
  String get tbUndo => 'Desfazer';

  @override
  String get tbRedo => 'Refazer';

  @override
  String get pgUnbookmark => 'Remover marcador';

  @override
  String get pgBookmark => 'Marcar página';

  @override
  String get pgShowAll => 'Mostrar todas';

  @override
  String get pgOnlyBookmarked => 'Só as marcadas';

  @override
  String get commonClose => 'Fechar';

  @override
  String get pgOptions => 'Opções da página';

  @override
  String get pgNew => 'Nova página';

  @override
  String get tagTitle => 'Etiquetas do caderno';

  @override
  String get tagSubtitle =>
      'Para encontrá-lo e agrupá-lo em pastas inteligentes';

  @override
  String get tagActive => 'Etiquetas ativas';

  @override
  String get tagOthers => 'Outras etiquetas';

  @override
  String get tagNew => 'Nova etiqueta…';

  @override
  String get tagAdd => 'Adicionar etiqueta';

  @override
  String get tagSave => 'Salvar etiquetas';

  @override
  String get trashDeleteForever => 'Excluir permanentemente';

  @override
  String get trashEmptyTitle => 'Esvaziar lixeira';

  @override
  String get trashEmpty => 'Esvaziar';

  @override
  String get trashSubtitleEmpty => 'O que você exclui fica aqui por 30 dias';

  @override
  String get trashEmptyState => 'A lixeira está vazia';

  @override
  String get trashLegacy => 'Caderno (formato antigo)';

  @override
  String get trashNote => 'Nota';

  @override
  String get trashReturn => 'Devolver ao caderno';

  @override
  String get strokeSubtitle => 'Pressão, suavização e fluidez do traço';

  @override
  String get strokeNone => 'A borracha e a seleção não têm opções de traço.';

  @override
  String get strokeQuickSize => 'Tamanho rápido';

  @override
  String get strokePressure => 'Variação de pressão';

  @override
  String get strokePressureDesc => 'Quanto a espessura muda ao pressionar';

  @override
  String get strokeSmoothing => 'Suavização';

  @override
  String get strokeSmoothingDesc => 'Arredonda as curvas do traço';

  @override
  String get strokeStabilizer => 'Estabilizador';

  @override
  String get strokeStabilizerDesc => 'Reduz o tremor da mão';

  @override
  String get strokeReset => 'Redefinir ajustes';

  @override
  String get sizeThin => 'Fino';

  @override
  String get sizeMedium => 'Médio';

  @override
  String get sizeThick => 'Grosso';

  @override
  String get sizeExtra => 'Extra';

  @override
  String get sizeSmall => 'Pequeno';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get toolPen => 'Caneta esferográfica';

  @override
  String get toolPencil => 'Lápis';

  @override
  String get toolCalligraphy => 'Caneta caligráfica';

  @override
  String get toolBrush => 'Pincel';

  @override
  String get toolMarker => 'Marcador';

  @override
  String get toolSpray => 'Spray';

  @override
  String get toolEraser => 'Borracha';

  @override
  String get toolSelect => 'Mover / selecionar';

  @override
  String get toolLasso => 'Laço';

  @override
  String get toolFill => 'Preenchimento';

  @override
  String get toolText => 'Texto';

  @override
  String selRecognizeFailed(String error) {
    return 'Não foi possível reconhecer: $error';
  }

  @override
  String tbPenSlot(String tool, int n) {
    return '$tool $n';
  }

  @override
  String get canvasSemantics => 'Tela de desenho';

  @override
  String tbPageOf(int n, int total) {
    return 'Página $n de $total';
  }

  @override
  String pgPagesCount(int n) {
    return 'Páginas ($n)';
  }

  @override
  String strokeOptionsOf(String tool) {
    return 'Opções de $tool';
  }

  @override
  String trashRestoredMsg(String title) {
    return '\"$title\" restaurado';
  }

  @override
  String trashPurgeBody(String title) {
    return '\"$title\" será excluído permanentemente. Isso não pode ser desfeito.';
  }

  @override
  String trashEmptyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens serão excluídos permanentemente',
      one: '1 item será excluído permanentemente',
    );
    return '$_temp0. Isso não pode ser desfeito.';
  }

  @override
  String trashSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0 · excluídos automaticamente após 30 dias';
  }

  @override
  String get trashEmptyStateBody =>
      'Os cadernos e notas que você exclui ficam aqui por 30 dias antes de serem removidos de vez.';

  @override
  String trashNotebookKind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return 'Caderno · $_temp0';
  }

  @override
  String trashNoteOf(String title) {
    return 'Nota de “$title”';
  }

  @override
  String get trashLeftTomorrow => 'excluído amanhã';

  @override
  String trashLeftDays(int n) {
    return 'faltam $n dias';
  }

  @override
  String trashInfoLine(String what, String deleted, String left) {
    return '$what · $deleted · $left';
  }

  @override
  String get edLayerLocked => 'Camada bloqueada — desbloqueie para editar';

  @override
  String get expTitle => 'Opções de exportação';

  @override
  String get expLow => 'Baixa (1024 px)';

  @override
  String get expMedium => 'Média (2048 px)';

  @override
  String get expHigh => 'Alta (4096 px)';

  @override
  String get expMax => 'Máxima (8192 px)';

  @override
  String get expTransparent => 'Fundo transparente';

  @override
  String get expTransparentHint => 'Sem modelo nem papel';

  @override
  String get expStrokesOnly => 'Só os traços';

  @override
  String get expStrokesOnlyHint => 'Sem imagens nem modelo';

  @override
  String get expExport => 'Exportar';

  @override
  String get ocrUnsupported => 'O OCR só está disponível no Android e no iOS';

  @override
  String get ocrWorking => 'Reconhecendo texto…';

  @override
  String get ocrNoText => 'Nenhum texto reconhecido nesta página';

  @override
  String get ocrResultTitle => 'Texto reconhecido';

  @override
  String get ocrCopied => 'Texto copiado para a área de transferência';

  @override
  String get edGoogleAccount => 'Conta do Google';

  @override
  String get edSyncedCloud => 'Sincronizado com a nuvem';

  @override
  String get edRestoreCloud => 'Restaurar da nuvem';

  @override
  String get edRestoreCloudHint => 'Última versão (vence a última gravação)';

  @override
  String get edDriveVersions => 'Ver versões no Drive';

  @override
  String get edUploadInklus => 'Enviar arquivo .inklus';

  @override
  String get edSyncOnForNotebook => 'Sincronização: ativada neste caderno';

  @override
  String get edSyncOffForNotebook => 'Sincronização: desativada neste caderno';

  @override
  String get edSyncDisabledMsg => 'Sincronização desativada para este caderno';

  @override
  String get edSyncEnabledMsg => 'Sincronização ativada para este caderno';

  @override
  String get edNoteSynced => 'Nota sincronizada com o Google Drive';

  @override
  String get edPasswordHint =>
      'Senha (deixe vazio se não estiver criptografado)';

  @override
  String get edNoCloudCopy => 'Ainda não há cópia desta nota no Google Drive';

  @override
  String get edNoteRestored => 'Nota restaurada do Google Drive';

  @override
  String get edIsFullBackup =>
      'Esse arquivo é um backup completo, não um caderno .inklus';

  @override
  String get edNoPassword => 'Sem senha';

  @override
  String get edNotebookTitle => 'Título do caderno';

  @override
  String get pdfUnsupported =>
      'Importar PDFs só está disponível no Android/iOS por enquanto';

  @override
  String get pdfReadFailed => 'Não foi possível ler o PDF';

  @override
  String get verRestoreTitle => 'Restaurar versão';

  @override
  String get verRestored => 'Versão restaurada';

  @override
  String get verEncrypted => 'Cópia criptografada';

  @override
  String get verPasswordHint => 'Senha da cópia';

  @override
  String get verDecrypt => 'Descriptografar';

  @override
  String get inkUnsupported =>
      'O reconhecimento de escrita à mão só está disponível no Android e no iOS';

  @override
  String get edDeleteImage => 'Excluir imagem';

  @override
  String get edExitPresent => 'Sair da apresentação';

  @override
  String get edLaserOff => 'Desligar laser';

  @override
  String get edGoToPage => 'Ir para a página';

  @override
  String get edGo => 'Ir';

  @override
  String get edNoStickers => 'Você ainda não tem adesivos instalados.';

  @override
  String get edOpenMarket => 'Abrir o marketplace';

  @override
  String get edSyncing => 'Sincronizando…';

  @override
  String get edSyncToDrive => 'Sincronizar com o Google Drive';

  @override
  String get edSynced => 'Sincronizado';

  @override
  String get edSyncError => 'Erro de sincronização';

  @override
  String get menuPagePng => 'Página como imagem (PNG)';

  @override
  String get menuPagePdf => 'Página como PDF';

  @override
  String get menuNotePdf => 'Nota inteira (PDF)';

  @override
  String get menuStrokesSvg => 'Traços (SVG)';

  @override
  String get menuPptx => 'Apresentação (PowerPoint)';

  @override
  String get menuInklusCopy => 'Copiar como .inklus';

  @override
  String get menuShareImage => 'Compartilhar imagem';

  @override
  String get menuSharePdf => 'Compartilhar PDF';

  @override
  String get menuShareInklus => 'Compartilhar .inklus';

  @override
  String get menuExportShare => 'Exportar e compartilhar';

  @override
  String get menuTemplate => 'Modelo…';

  @override
  String get menuGoToPage => 'Ir para a página…';

  @override
  String get menuImportPdf => 'Importar PDF para anotar';

  @override
  String get menuClearPage => 'Limpar página';

  @override
  String get menuPage => 'Página';

  @override
  String get menuSearchNote => 'Buscar na nota';

  @override
  String get menuIndexInk => 'Indexar escrita à mão (para buscá-la)';

  @override
  String get menuIndexInkUnsupported =>
      'Indexar escrita à mão (só Android/iOS)';

  @override
  String get menuOcr => 'Reconhecer texto (OCR)';

  @override
  String get menuOcrUnsupported => 'OCR (só Android/iOS)';

  @override
  String get menuVersions => 'Histórico de versões';

  @override
  String get menuReminder => 'Criar lembrete';

  @override
  String get menuNightOff => 'Desativar modo noturno';

  @override
  String get menuNightOn => 'Modo noturno de escrita';

  @override
  String get menuPresent => 'Modo apresentação';

  @override
  String get menuHapticsOn => 'Vibração ao escrever: ativada';

  @override
  String get menuHapticsOff => 'Vibração ao escrever: desativada';

  @override
  String get menuContinuousScroll => 'Rolagem contínua entre folhas';

  @override
  String get menuView => 'Exibir';

  @override
  String get menuBackup => 'Exportar backup completo';

  @override
  String get menuRestoreBackup => 'Importar .inklus ou backup';

  @override
  String get menuData => 'Dados';

  @override
  String get menuStats => 'Estatísticas de escrita';

  @override
  String get clearPageBody =>
      'Todo o conteúdo da página será apagado. Depois você pode desfazer.';

  @override
  String get clearPageAction => 'Limpar';

  @override
  String get pgPrev => 'Página anterior';

  @override
  String get pgNext => 'Próxima página';

  @override
  String get zoomOut => 'Diminuir zoom';

  @override
  String get zoomFit => 'Ajustar à tela';

  @override
  String get zoomIn => 'Aumentar zoom';

  @override
  String get shareTextPage => 'Página do Inklus';

  @override
  String get shareTextNotebook => 'Caderno do Inklus';

  @override
  String edInsertImageFailed(String error) {
    return 'Não foi possível inserir a imagem: $error';
  }

  @override
  String expSvgFailed(String error) {
    return 'Erro ao exportar SVG: $error';
  }

  @override
  String ocrFailed(String error) {
    return 'Erro no reconhecimento de texto: $error';
  }

  @override
  String expFailed(String error) {
    return 'Erro ao exportar: $error';
  }

  @override
  String expPreview(String name) {
    return 'Pré-visualização: $name';
  }

  @override
  String expSaveDialog(String name) {
    return 'Salvar $name';
  }

  @override
  String expDone(String path) {
    return 'Exportado: $path';
  }

  @override
  String expSaveFailed(String error) {
    return 'Não foi possível salvar o arquivo: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Erro ao compartilhar: $error';
  }

  @override
  String edSignInIncomplete(String detail) {
    return 'O login não foi concluído. Detalhe: $detail';
  }

  @override
  String uploadFailed(String error) {
    return 'Erro ao enviar: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Erro ao restaurar: $error';
  }

  @override
  String edFileUploaded(String name) {
    return 'Arquivo \"$name\" enviado ao Google Drive';
  }

  @override
  String pdfImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return 'PDF importado: $_temp0 para anotar';
  }

  @override
  String pdfImportFailed(String error) {
    return 'Erro ao importar PDF: $error';
  }

  @override
  String verRestoreBody(String date) {
    return 'A nota voltará a ser como era em $date.\\n\\nO estado atual é salvo antes como uma versão local, então você pode desfazer a restauração neste mesmo histórico.';
  }

  @override
  String verRestoreFailed(String error) {
    return 'Não foi possível restaurar a versão: $error';
  }

  @override
  String pptxFailed(String error) {
    return 'Erro ao exportar para PowerPoint: $error';
  }

  @override
  String reminderCreated(String date, String time) {
    return 'Lembrete criado para $date às $time';
  }

  @override
  String inkIndexed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return 'Escrita à mão indexada em $_temp0: agora você pode buscá-la';
  }

  @override
  String inkFailed(String error) {
    return 'Não foi possível reconhecer a escrita à mão: $error';
  }

  @override
  String backupFailed(String error) {
    return 'Erro ao exportar o backup: $error';
  }

  @override
  String importDoneOpen(String message) {
    return '$message. Abra-o pela biblioteca.';
  }

  @override
  String noteHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return 'A nota tem $_temp0';
  }

  @override
  String stickerInsertFailed(String error) {
    return 'Não foi possível inserir o adesivo: $error';
  }

  @override
  String get remNoNotebooks => 'Nenhum caderno para vincular';

  @override
  String get remPickNotebook => 'Selecione o caderno';

  @override
  String get remPickHint => 'O lembrete abrirá este caderno';

  @override
  String get remCreated => 'Lembrete criado';

  @override
  String get remMessageTitle => 'Mensagem do lembrete';

  @override
  String get remMessageHint => 'Ex.: Revisar as notas de aula';

  @override
  String get remNoMessage => 'Sem mensagem';

  @override
  String get remTitle => 'Lembretes';

  @override
  String get remSubtitle => 'Avisos ligados aos seus cadernos';

  @override
  String get remEmptyTitle => 'Nenhum lembrete';

  @override
  String get remPending => 'Pendentes';

  @override
  String get remDone => 'Concluídos';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsSubtitle => 'Sua atividade de escrita neste dispositivo';

  @override
  String get statsEmptyTitle => 'Ainda sem dados';

  @override
  String get statsStrokes => 'Traços';

  @override
  String get statsMinutes => 'Minutos';

  @override
  String get statsActiveDays => 'Dias ativos';

  @override
  String get statsStreaks => 'Sequências';

  @override
  String get statsCurrentStreak => 'Sequência atual';

  @override
  String get statsRecord => 'Recorde';

  @override
  String get statsActivity => 'Atividade — últimos 30 dias';

  @override
  String get statsDaysWithPages => 'Dias com páginas novas';

  @override
  String get smartTitle => 'Pastas inteligentes';

  @override
  String get smartSubtitle => 'Organize seus cadernos automaticamente';

  @override
  String get smartByColor => 'Por cor';

  @override
  String get smartByTag => 'Por etiqueta';

  @override
  String get onbSkip => 'Pular';

  @override
  String get onbStart => 'Começar';

  @override
  String get onb1Title => 'Escreva com a caneta';

  @override
  String get onb2Title => 'Mova com os dedos';

  @override
  String get onb3Title => 'Ferramentas no topo';

  @override
  String get onb4Title => 'Suas notas são suas';

  @override
  String get layerAdd => 'Adicionar camada';

  @override
  String get layerRename => 'Renomear camada';

  @override
  String get verSubtitle => 'Ao restaurar, o estado atual é salvo antes';

  @override
  String get verOnDevice => 'Neste dispositivo';

  @override
  String get verNoLocal => 'Ainda não há cópias locais desta nota.';

  @override
  String get verOnDrive => 'No Google Drive';

  @override
  String get verNotUploaded => 'Esta nota ainda não foi enviada ao Drive.';

  @override
  String get smartThisWeek => 'Esta semana';

  @override
  String get smartNoTags => 'Sem etiquetas';

  @override
  String get smartOther => 'Outras';

  @override
  String get colorNone => 'Sem cor';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorRed => 'Vermelho';

  @override
  String get colorOrange => 'Laranja';

  @override
  String get colorPurple => 'Roxo';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorTurquoise => 'Turquesa';

  @override
  String get colorGray => 'Cinza';

  @override
  String get onb1Body =>
      'Apoie a mão sem preocupação: o Inklus reconhece a caneta e ignora a palma. A ponta-borracha da caneta ou o botão lateral apaga.';

  @override
  String get onb2Body =>
      'Com a caneta, um dedo rola a página e dois dedos dão zoom. Você pode voltar a desenhar com o dedo pela barra de ferramentas.';

  @override
  String get onb3Body =>
      'Toque em uma ferramenta para usá-la e toque de novo para ver suas opções: espessura, cor, borracha parcial, formas…';

  @override
  String get onb4Body =>
      'Tudo fica salvo neste dispositivo, sem contas nem anúncios. Se quiser, você pode fazer backup no seu Google Drive.';

  @override
  String get remEmptyBody =>
      'Crie lembretes vinculados aos seus cadernos para nunca esquecer nada.';

  @override
  String get statsEmptyBody =>
      'Comece a escrever nos seus cadernos e suas estatísticas aparecerão aqui.';

  @override
  String get remOverdue => ' · atrasado';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String statsDayTooltip(String date, int strokes, int pages) {
    return '$date: $strokes traços, $pages páginas';
  }

  @override
  String get searchInNote => 'Buscar nesta nota';

  @override
  String get searchInAll => 'Buscar em todas as notas';

  @override
  String get searchPrompt => 'Digite para buscar';

  @override
  String searchMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get searchInfo =>
      'Inclui caixas de texto e escrita à mão que já foi reconhecida (menu Nota → Indexar escrita à mão).';

  @override
  String get searchTitleMatch => 'Título';

  @override
  String get pgDuplicate => 'Duplicar página';

  @override
  String get pgDelete => 'Excluir página';

  @override
  String verDriveFailed(String error) {
    return 'Não foi possível consultar o Drive: $error';
  }

  @override
  String colorSemantics(String hex) {
    return 'Cor #$hex';
  }

  @override
  String get errNotInklus =>
      'O arquivo não é um caderno .inklus nem um backup do Inklus.';

  @override
  String get errNotInklusFile => 'Não é um caderno .inklus válido';

  @override
  String get errNotInklusV2 => 'Não é um caderno .inklus v2 válido';

  @override
  String get errCatalogTooLarge => 'O catálogo é grande demais';

  @override
  String errCatalogVersion(String version) {
    return 'Versão de catálogo não suportada: $version';
  }

  @override
  String get errOcrUnsupported =>
      'O OCR só está disponível no Android e no iOS.';

  @override
  String get errNotSignedIn => 'Entre com o Google primeiro.';

  @override
  String get errEncrypted =>
      'A cópia está criptografada: é necessária uma senha';

  @override
  String driveConfigBody(String details) {
    return 'Erro de configuração do Google (clientConfigurationError).\\n\\nCausa provável: o SHA-1 de assinatura deste app não está registrado no Google Cloud Console para o pacote com.inklus.inklus.\\n\\nSolução:\\n1. Vá a Google Cloud Console → APIs e serviços → Credenciais\\n2. Crie ou edite o ID de cliente OAuth do Android com o pacote com.inklus.inklus e o seu SHA-1 de assinatura\\n3. Ative o Google Sign-In na tela de consentimento\\n\\nErro original: $details';
  }

  @override
  String get noticeStylus =>
      'Caneta detectada: agora o dedo rola a página (ative na barra de ferramentas se quiser desenhar com o dedo)';

  @override
  String get noticePageDeleted => 'Página excluída';

  @override
  String get noticeFileUploaded => 'Arquivo enviado ao Google Drive';

  @override
  String importBackupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cadernos',
      one: '1 caderno',
    );
    return 'Backup restaurado: $_temp0';
  }

  @override
  String importNotebookDone(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return 'Caderno \"$title\" importado ($_temp0)';
  }

  @override
  String importNotebookSimple(String title) {
    return 'Caderno \"$title\" importado';
  }

  @override
  String get driveRestoreNone => 'Não há cópias do Inklus no seu Google Drive';

  @override
  String get driveRestoreUpToDate => 'Tudo está em dia: nada para restaurar';

  @override
  String driveRestoreUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas atualizadas',
      one: '1 nota atualizada',
    );
    return '$_temp0';
  }

  @override
  String driveRestoreAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recuperadas',
      one: '1 recuperada',
    );
    return '$_temp0';
  }

  @override
  String get driveRecovered => 'Recuperado do Drive';

  @override
  String get packClassicName => 'Cadernos clássicos';

  @override
  String get packClassicDesc =>
      'Pauta larga e estreita, quadriculado de 5 mm, pontos e pentagrama.';

  @override
  String get packTechName => 'Papel técnico';

  @override
  String get packTechDesc =>
      'Quadriculado fino de papel milimetrado e agenda em colunas, em tons suaves.';

  @override
  String get packStudyName => 'Paleta de estudo';

  @override
  String get packStudyDesc =>
      'Tinta azul e preta, vermelho de correção, verde e laranja para destacar.';

  @override
  String get packPastelName => 'Paleta pastel';

  @override
  String get packPastelDesc => 'Tons suaves para notas e diagramas bonitos.';

  @override
  String get packEarthName => 'Paleta terra';

  @override
  String get packEarthDesc =>
      'Ocres, oliva e terracota, com bom contraste no papel.';

  @override
  String get coverSimple => 'Degradê';

  @override
  String get coverClassic => 'Clássica';

  @override
  String get coverAurora => 'Aurora';

  @override
  String get coverWaves => 'Ondas';

  @override
  String get coverGeometric => 'Geométrica';

  @override
  String get coverSun => 'Sol';

  @override
  String get coverDots => 'Pontos';

  @override
  String get coverLines => 'Linhas';

  @override
  String get untitled => 'Sem título';

  @override
  String get defaultNotebookTitle => 'Meu caderno';

  @override
  String get createFromFile => 'Ou comece a partir de um arquivo';

  @override
  String get createFromFileHint =>
      'Envie um PDF ou fotos e escreva sobre cada página.';

  @override
  String get createFromPdf => 'De um PDF';

  @override
  String get createFromImages => 'De imagens';

  @override
  String get createFromFileRemove => 'Remover arquivo';

  @override
  String createFromFilePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0';
  }

  @override
  String get menuTwoFingerUndo => 'Desfazer com toque de dois dedos';

  @override
  String get popEraserAutoRevert =>
      'Voltar à ferramenta anterior depois de apagar';

  @override
  String get saveFailed =>
      'Não foi possível salvar a nota. Libere espaço: ela tentará de novo automaticamente.';

  @override
  String get tplHalfLetter => 'Meia carta';
}
