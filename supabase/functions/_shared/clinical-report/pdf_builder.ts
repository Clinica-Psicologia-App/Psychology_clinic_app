import { PDFDocument, StandardFonts, rgb } from "pdf-lib";
import type { ReportData, ReportInclude } from "./types.ts";
import { REPORT_VERSION } from "./types.ts";

const PAGE_WIDTH = 595;
const PAGE_HEIGHT = 842;
const MARGIN = 50;
const LINE_HEIGHT = 14;
const BODY_SIZE = 10;
const TITLE_SIZE = 16;
const HEADING_SIZE = 12;

const CLINICAL_NOTICE =
  "Relatorio gerado como apoio clinico. A interpretacao e responsabilidade do profissional.";
const DISCLAIMER =
  "Este documento nao constitui diagnostico automatico. Uso supervisionado pelo psicologo responsavel.";

type PdfWriter = {
  doc: PDFDocument;
  page: ReturnType<PDFDocument["addPage"]>;
  font: Awaited<ReturnType<PDFDocument["embedFont"]>>;
  fontBold: Awaited<ReturnType<PDFDocument["embedFont"]>>;
  y: number;
};

function sanitize(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^\x20-\x7E]/g, "?")
    .trim();
}

function wrapLines(text: string, maxChars: number): string[] {
  const words = sanitize(text).split(/\s+/).filter(Boolean);
  if (words.length === 0) return [""];
  const lines: string[] = [];
  let current = "";
  for (const word of words) {
    const next = current ? `${current} ${word}` : word;
    if (next.length > maxChars && current) {
      lines.push(current);
      current = word;
    } else {
      current = next;
    }
  }
  if (current) lines.push(current);
  return lines;
}

async function newWriter(): Promise<PdfWriter> {
  const doc = await PDFDocument.create();
  const page = doc.addPage([PAGE_WIDTH, PAGE_HEIGHT]);
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const fontBold = await doc.embedFont(StandardFonts.HelveticaBold);
  return { doc, page, font, fontBold, y: PAGE_HEIGHT - MARGIN };
}

function ensureSpace(writer: PdfWriter, needed: number): void {
  if (writer.y - needed >= MARGIN) return;
  writer.page = writer.doc.addPage([PAGE_WIDTH, PAGE_HEIGHT]);
  writer.y = PAGE_HEIGHT - MARGIN;
}

function drawLine(
  writer: PdfWriter,
  text: string,
  opts?: { bold?: boolean; size?: number },
): void {
  const size = opts?.size ?? BODY_SIZE;
  const font = opts?.bold ? writer.fontBold : writer.font;
  const maxChars = Math.floor((PAGE_WIDTH - 2 * MARGIN) / (size * 0.5));
  for (const line of wrapLines(text, maxChars)) {
    ensureSpace(writer, LINE_HEIGHT);
    writer.page.drawText(line, {
      x: MARGIN,
      y: writer.y,
      size,
      font,
      color: rgb(0.1, 0.1, 0.1),
    });
    writer.y -= LINE_HEIGHT;
  }
}

function drawHeading(writer: PdfWriter, text: string): void {
  writer.y -= 8;
  drawLine(writer, text, { bold: true, size: HEADING_SIZE });
  writer.y -= 4;
}

function drawTitle(writer: PdfWriter, text: string): void {
  drawLine(writer, text, { bold: true, size: TITLE_SIZE });
  writer.y -= 8;
}

function formatDate(iso: string | null): string {
  if (!iso) return "—";
  try {
    return iso.slice(0, 10);
  } catch {
    return iso;
  }
}

export async function buildClinicalReportPdf(
  data: ReportData,
  include: ReportInclude,
): Promise<Uint8Array> {
  const writer = await newWriter();
  const ctx = data.context;

  drawTitle(writer, sanitize(ctx.clinicName));
  drawLine(writer, "Relatorio Clinico — Terapia do Esquema");
  writer.y -= 12;
  drawLine(writer, `Paciente: ${ctx.patientName}`);
  if (ctx.psychologistName) {
    drawLine(writer, `Psicologo(a): ${ctx.psychologistName}`);
  }
  drawLine(writer, `Gerado em: ${formatDate(ctx.generatedAt)}`);
  writer.y -= 16;

  drawHeading(writer, "Aviso clinico");
  drawLine(writer, DISCLAIMER);
  drawLine(writer, CLINICAL_NOTICE);
  writer.y -= 8;

  drawHeading(writer, "Resumo do paciente");
  if (ctx.patientEmail) drawLine(writer, `E-mail: ${ctx.patientEmail}`);
  if (ctx.patientPhone) drawLine(writer, `Telefone: ${ctx.patientPhone}`);
  if (ctx.birthDate) {
    drawLine(writer, `Data de nascimento: ${formatDate(ctx.birthDate)}`);
  }
  writer.y -= 8;

  if (include.questionnaires && data.questionnaires.length > 0) {
    drawHeading(writer, "Questionarios clinicos");
    for (const block of data.questionnaires) {
      drawLine(writer, `${block.questionnaireName} (${block.questionnaireCode})`, {
        bold: true,
      });
      drawLine(
        writer,
        `Concluido em: ${formatDate(block.completedAt)}`,
      );
      drawLine(
        writer,
        `Revisao clinica: ${block.requiresTherapistReview ? "pendente" : "concluida"}`,
      );
      if (block.reviewedAt) {
        drawLine(writer, `Revisado em: ${formatDate(block.reviewedAt)}`);
      }
      if (block.reviewedByName) {
        drawLine(writer, `Revisado por: ${block.reviewedByName}`);
      }
      if (block.reviewNotes) {
        drawLine(writer, `Observacao da revisao: ${block.reviewNotes}`);
      }
      if (block.topScores.length === 0) {
        drawLine(writer, "Sem esquemas/modos estruturados no snapshot.");
      } else {
        for (const row of block.topScores) {
          const sev = row.severityLabel ? ` | ${row.severityLabel}` : "";
          drawLine(
            writer,
            `  ${row.name} (${row.code}): ${row.score.toFixed(2)}${sev}`,
          );
        }
      }
      writer.y -= 4;
    }
  } else if (include.questionnaires) {
    drawHeading(writer, "Questionarios");
    drawLine(writer, "Nenhum resultado clinico concluido.");
  }

  if (include.mental_map && data.mentalMap) {
    const m = data.mentalMap;
    drawHeading(writer, "Mapa mental resumido");
    if (m.therapyDemands) {
      drawLine(writer, `Demandas terapeuticas: ${m.therapyDemands}`);
    }
    if (m.currentLifeContext) {
      drawLine(writer, `Contexto de vida atual: ${m.currentLifeContext}`);
    }
    if (m.intakeSummary) {
      drawLine(writer, `Sintese inicial: ${m.intakeSummary}`);
    }
    drawLine(
      writer,
      `Revisoes concluidas: ${m.reviewedQuestionnaireCount} | Pendentes: ${m.pendingQuestionnaireReviewCount}`,
    );
    if (m.pendingQuestionnaireReviewCount > 0) {
      drawLine(
        writer,
        "A consolidacao clinica deste caso ainda depende da revisao do terapeuta nos instrumentos pendentes.",
      );
    }
    if (m.centralHypotheses.length > 0) {
      drawLine(writer, "Hipoteses centrais:");
      for (const item of m.centralHypotheses) {
        drawLine(writer, `  - ${item}`);
      }
    }
    if (m.currentFocuses.length > 0) {
      drawLine(writer, "Focos atuais:");
      for (const item of m.currentFocuses) {
        drawLine(writer, `  - ${item}`);
      }
    }
    drawLine(writer, `Problemas ativos: ${m.activeProblemCount}`);
    drawLine(writer, `Objetivos ativos: ${m.activeGoalCount}`);
    if (m.latestCheckInAt) {
      drawLine(
        writer,
        `Ultimo check-in: ${formatDate(m.latestCheckInAt)}` +
          (m.latestCheckInMood != null
            ? ` (humor: ${m.latestCheckInMood})`
            : ""),
      );
    }
    if (m.latestMonitorAt) {
      drawLine(writer, `Ultimo monitor: ${formatDate(m.latestMonitorAt)}`);
    }
    drawLine(
      writer,
      `Genograma: ${m.genogramPeopleCount} pessoa(s), ${m.genogramRelationshipCount} relacao(oes)`,
    );
    if (m.recentTimelineTitles.length > 0) {
      drawLine(writer, "Linha do tempo recente:");
      for (const t of m.recentTimelineTitles) {
        drawLine(writer, `  - ${t}`);
      }
    }
    if (m.suggestedResources.length > 0) {
      drawLine(writer, "Sugestoes terapeuticas iniciais:");
      for (const item of m.suggestedResources) {
        drawLine(writer, `  - ${item.title}`);
        for (const reason of item.reasons) {
          drawLine(writer, `    * ${reason}`);
        }
      }
    }
    writer.y -= 8;
  }

  if (include.problems && data.problems.length > 0) {
    drawHeading(writer, "Problemas");
    for (const p of data.problems) {
      const inten = p.intensity != null ? ` | intensidade ${p.intensity}` : "";
      drawLine(writer, `- ${p.title} (${p.status})${inten}`);
    }
    writer.y -= 4;
  }

  if (include.goals && data.goals.length > 0) {
    drawHeading(writer, "Objetivos da terapia");
    for (const g of data.goals) {
      drawLine(writer, `- ${g.title} (${g.status})`);
      if (g.description) drawLine(writer, `  ${g.description}`);
    }
    writer.y -= 4;
  }

  if (include.check_ins && data.checkIns.length > 0) {
    drawHeading(writer, "Ultimos check-ins");
    for (const c of data.checkIns) {
      drawLine(
        writer,
        `${formatDate(c.checkedInAt)} | humor ${c.mood ?? "—"} | ansiedade ${c.anxiety ?? "—"} | energia ${c.energy ?? "—"}`,
      );
      if (c.notes) drawLine(writer, `  Notas: ${c.notes}`);
    }
    writer.y -= 4;
  }

  if (include.daily_monitors && data.dailyMonitors.length > 0) {
    drawHeading(writer, "Ultimos registros de monitor diario");
    for (const m of data.dailyMonitors) {
      drawLine(writer, formatDate(m.createdAt));
      if (m.moodNotes) drawLine(writer, `  Humor: ${m.moodNotes}`);
      if (m.sleepNotes) drawLine(writer, `  Sono: ${m.sleepNotes}`);
      if (m.activityNotes) drawLine(writer, `  Atividade: ${m.activityNotes}`);
    }
    writer.y -= 4;
  }

  if (include.timeline && data.timelineEvents.length > 0) {
    drawHeading(writer, "Linha do tempo");
    for (const e of data.timelineEvents) {
      const when = e.eventDate
        ? formatDate(e.eventDate)
        : (e.periodLabel ?? "—");
      drawLine(writer, `- ${e.title} (${when})`);
      if (e.category) drawLine(writer, `  Categoria: ${e.category}`);
    }
    writer.y -= 4;
  }

  if (include.genogram) {
    drawHeading(writer, "Genograma");
    if (data.genogramPeople.length === 0) {
      drawLine(writer, "Nenhuma pessoa registrada.");
    } else {
      for (const p of data.genogramPeople) {
        const extra = [
          p.gender ? `genero ${p.gender}` : null,
          p.birthYear ? `nasc. ${p.birthYear}` : null,
        ].filter(Boolean).join(", ");
        drawLine(
          writer,
          `- ${p.displayName}${extra ? ` (${extra})` : ""}`,
        );
      }
    }
    if (data.genogramRelationships.length > 0) {
      drawLine(writer, "Relacoes:");
      for (const r of data.genogramRelationships) {
        drawLine(writer, `  ${r.personA} — ${r.personB}: ${r.type}`);
      }
    }
  }

  ensureSpace(writer, 40);
  writer.y = MARGIN + 20;
  drawLine(
    writer,
    `Rodape | ${formatDate(ctx.generatedAt)} ${ctx.generatedAt.slice(11, 19)} UTC | ${REPORT_VERSION}`,
  );
  drawLine(writer, "Sem assinatura digital automatica.");

  return writer.doc.save();
}
