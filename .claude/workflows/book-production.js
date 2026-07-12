export const meta = {
  name: 'book-production',
  description: 'Viết sách đa chương bằng multi-agent theo book-plan đã duyệt: mỗi chương 1 writer song song, mỗi chương 1 verifier đối chiếu plan+style, tổng hợp về main loop',
  whenToUse: 'Sau khi user đã DUYỆT book-plan.md + style-profile.md (foxai-book-writer giai đoạn 2-3). Args: {planPath, stylePath, chapters:[{number,title,goal,points:[],callouts,words,illustration}], sourcePath?}',
  phases: [
    { title: 'Write', detail: 'mỗi chương một writer agent, đọc plan + style profile' },
    { title: 'Verify', detail: 'mỗi chương một verifier đối chiếu ý chính + style' },
  ],
}

// args có thể tới dạng chuỗi JSON tùy môi trường — parse phòng thủ
let plan = args
if (typeof plan === 'string') { try { plan = JSON.parse(plan) } catch (e) { plan = null } }
if (!plan || !Array.isArray(plan.chapters) || plan.chapters.length === 0) {
  return { error: 'Thiếu args.chapters — truyền kế hoạch chương ĐÃ ĐƯỢC USER DUYỆT (object JSON). Không chạy workflow này trước cổng duyệt.' }
}
const planPath = plan.planPath, stylePath = plan.stylePath, sourcePath = plan.sourcePath

const CH_SCHEMA = {
  type: 'object', required: ['number', 'content_markdown', 'image_prompt', 'notes'],
  properties: {
    number: { type: 'number' },
    content_markdown: { type: 'string', description: 'Nội dung chương theo cú pháp content của foxai-book-writer (##, >, !b/!t/!d/!l/!p/!c/!g, **bold**)' },
    image_prompt: { type: 'string', description: 'Prompt EN sinh ảnh minh họa theo templates/image-prompts.md; chuỗi rỗng nếu plan không yêu cầu ảnh' },
    notes: { type: 'string', description: 'Giả định/điểm cần user quyết — chuỗi rỗng nếu không có' },
  },
}
const VERDICT_SCHEMA = {
  type: 'object', required: ['pass', 'missing_points', 'style_violations', 'evidence'],
  properties: {
    pass: { type: 'boolean' },
    missing_points: { type: 'array', items: { type: 'string' } },
    style_violations: { type: 'array', items: { type: 'string' } },
    evidence: { type: 'string', description: 'Trích dẫn cụ thể chứng minh kết luận' },
  },
}

const writerPrompt = (ch) => `Bạn là writer trong quy trình foxai-book-writer. Viết CHƯƠNG ${ch.number}: "${ch.title}".
Bắt buộc đọc trước bằng Read: ${stylePath} (tuân thủ tuyệt đối, nhất là mục 4 đoạn mẫu và mục 5 điều CẤM) và ${planPath} (hàng chương ${ch.number}).${sourcePath ? ` Bản thảo raw tham khảo: ${sourcePath} (trung thành nội dung nguồn, không bịa thêm số liệu).` : ''}
Yêu cầu từ plan — mục tiêu: ${ch.goal || '(xem plan)'} · ý chính bắt buộc: ${(ch.points || []).join(' | ') || '(xem plan)'} · callout: ${ch.callouts || 'theo plan'} · độ dài: ~${ch.words || 800} từ · minh họa: ${ch.illustration || 'không'}.
Viết bằng tiếng Việt theo cú pháp content markdown của skill (## heading, > quote, hộp !b/!t/!d/!l/!p/!c/!g, đoạn cách nhau dòng trống). Zero fabrication: không bịa số liệu/trích dẫn ngoài nguồn. Trả về đúng schema.`

const verifierPrompt = (ch, draft) => `Bạn là verifier độc lập (chuẩn foxai-book-verifier). KHÔNG tin writer.
Đọc ${planPath} (hàng chương ${ch.number}) và ${stylePath}, rồi đối chiếu bản thảo chương dưới đây:
1) TỪNG ý chính bắt buộc có mặt chưa — trích câu chứng minh cho mỗi ý; thiếu 1 ý = pass:false.
2) Vi phạm điều CẤM trong style-profile mục 5 = pass:false.
3) Xưng hô + giọng có khớp style-profile không.
--- BẢN THẢO CHƯƠNG ${ch.number} ---
${draft.content_markdown}
--- HẾT ---`

const results = await pipeline(
  plan.chapters,
  (ch) => agent(writerPrompt(ch), { label: `write:ch${ch.number}`, phase: 'Write', schema: CH_SCHEMA }),
  (draft, ch) => !draft ? null :
    agent(verifierPrompt(ch, draft), { label: `verify:ch${ch.number}`, phase: 'Verify', schema: VERDICT_SCHEMA })
      .then(v => ({ chapter: ch.number, title: ch.title, draft, verdict: v })),
)

const done = results.filter(Boolean)
const passed = done.filter(r => r.verdict && r.verdict.pass)
const failed = done.filter(r => !r.verdict || !r.verdict.pass)
log(`Hoàn tất: ${passed.length}/${plan.chapters.length} chương PASS verify, ${failed.length} chương cần sửa`)
return {
  summary: { total: plan.chapters.length, passed: passed.length, failed: failed.map(f => f.chapter) },
  chapters: done,
  next_steps: 'Main loop: sửa các chương FAIL theo verdict → ghép content vào book JSON → sinh sách bằng generate_book.py → chạy agent foxai-book-verifier lần cuối trên toàn sách.',
}
