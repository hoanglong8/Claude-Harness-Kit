export const meta = {
  name: 'agent-factory',
  description: 'Nhà máy hệ multi-agent FOXAI: mode=design (3 kiến trúc sư độc lập + judge chấm) hoặc mode=build (mỗi component 1 builder trả về content + 1 reviewer đối chiếu spec)',
  whenToUse: 'Gọi từ skill foxai-agent-factory. design: GĐ2 hệ phức tạp. build: GĐ4 khi >4 component. Args design: {mode:"design", domain, requirements, constraints, modelPolicy}. Args build: {mode:"build", blueprintPath, components:[{type,name,spec}]}',
  phases: [
    { title: 'Design', detail: '3 kiến trúc sư: chi phí tối giản / độ tin cậy / tốc độ song song' },
    { title: 'Judge', detail: 'chấm điểm + tổng hợp blueprint đề xuất' },
    { title: 'Build', detail: 'mỗi component 1 builder trả về nội dung file' },
    { title: 'Review', detail: 'mỗi component 1 reviewer đối chiếu spec trước khi main loop ghi file' },
  ],
}

let a = args
if (typeof a === 'string') { try { a = JSON.parse(a) } catch (e) { a = null } }
if (!a || !a.mode) return { error: 'Thiếu args.mode ("design" | "build") — xem whenToUse.' }

// ================= MODE DESIGN =================
if (a.mode === 'design') {
  if (!a.domain || !a.requirements) return { error: 'mode=design cần args.domain và args.requirements (từ intake GĐ1 đã có trả lời của user).' }
  const BLUEPRINT_SCHEMA = {
    type: 'object', required: ['pattern', 'agents', 'rationale', 'estimated_tokens_per_run', 'risks'],
    properties: {
      pattern: { type: 'string', description: 'solo+skill | pipeline | orchestrator-workers | judge-panel | hybrid' },
      agents: { type: 'array', items: { type: 'object', required: ['name', 'role', 'tools', 'model'], properties: {
        name: { type: 'string' }, role: { type: 'string' }, tools: { type: 'string' }, model: { type: 'string' },
        forbidden: { type: 'string' } } } },
      rationale: { type: 'string' },
      estimated_tokens_per_run: { type: 'number' },
      risks: { type: 'array', items: { type: 'string' } },
    },
  }
  const ANGLES = [
    ['cost', 'CHI PHÍ TỐI GIẢN: ít agent nhất, tier model thấp nhất đủ dùng, đơn giản vận hành. Phản biện bắt buộc: multi-agent hóa có thật sự cần không?'],
    ['reliability', 'ĐỘ TIN CẬY: verifier độc lập cho mọi đầu ra quan trọng, adversarial check, không tin claim. Chấp nhận tốn hơn để không sai.'],
    ['speed', 'TỐC ĐỘ & SONG SONG: tối đa hóa pipeline/parallel, wall-clock ngắn nhất, chỉ verify điểm nghẽn.'],
  ]
  const proposals = await parallel(ANGLES.map(([key, angle]) => () =>
    agent(`Bạn là kiến trúc sư hệ multi-agent của FOXAI, thiết kế theo góc nhìn ${angle}
Lĩnh vực: ${a.domain}
Yêu cầu từ intake: ${a.requirements}
Ràng buộc: ${a.constraints || 'không có thêm'} · Chính sách model: ${a.modelPolicy || 'chỉ Anthropic (haiku/sonnet/opus)'}
Quy tắc bắt buộc: (1) hệ PHẢI có 1 verifier độc lập; (2) map model theo tier rẻ-nhất-đủ-dùng (haiku=bulk, sonnet=có-scope, opus=phán đoán khó); (3) role cần model ngoài Claude phải là tool-call step, không phải agent; (4) khai rõ hành vi cấm cho từng agent; (5) ước lượng token thành thật, không tô vẽ. Trả về đúng schema.`,
      { label: `architect:${key}`, phase: 'Design', schema: BLUEPRINT_SCHEMA })))
  const valid = proposals.filter(Boolean)
  if (!valid.length) return { error: 'Cả 3 kiến trúc sư đều lỗi — xem journal.jsonl' }
  const JUDGE_SCHEMA = {
    type: 'object', required: ['winner_index', 'scores', 'synthesis', 'what_would_change_verdict'],
    properties: {
      winner_index: { type: 'number' },
      scores: { type: 'array', items: { type: 'object', required: ['index', 'fit', 'cost', 'reliability', 'total'], properties: {
        index: { type: 'number' }, fit: { type: 'number' }, cost: { type: 'number' }, reliability: { type: 'number' }, total: { type: 'number' } } } },
      synthesis: { type: 'string', description: 'Blueprint tổng hợp: lấy phương án thắng làm khung, ghép điểm mạnh đáng giá từ phương án khác, ghi rõ ghép gì từ đâu' },
      what_would_change_verdict: { type: 'string' },
    },
  }
  const judge = await agent(`Bạn là judge của FOXAI (chuẩn fable-critic: không rubber-stamp, tấn công giả định, chấm theo hậu quả).
Lĩnh vực: ${a.domain} · Yêu cầu: ${a.requirements} · Chính sách model: ${a.modelPolicy || 'chỉ Anthropic'}
Chấm ${valid.length} phương án kiến trúc sau theo 3 tiêu chí (fit với yêu cầu /10, chi phí /10 — rẻ hơn điểm cao, độ tin cậy /10):
${valid.map((p, i) => `--- PHƯƠNG ÁN ${i} ---\n${JSON.stringify(p)}`).join('\n')}
Nghi vấn bắt buộc kiểm: phương án có over-engineer không (việc 1 agent làm được mà vẽ 5 agent)? verifier có thật không hay chỉ tên gọi? ước lượng token có thành thật không?`,
    { label: 'judge', phase: 'Judge', schema: JUDGE_SCHEMA, effort: 'high' })
  log(`Design xong: ${valid.length} phương án, judge chọn #${judge ? judge.winner_index : '?'}`)
  return { mode: 'design', proposals: valid, judge,
    next_steps: 'Main loop: điền blueprint từ judge.synthesis vào templates/agent-blueprint.md → DỪNG chờ user duyệt (GĐ3) → mới build.' }
}

// ================= MODE BUILD =================
if (a.mode === 'build') {
  if (!Array.isArray(a.components) || !a.components.length) return { error: 'mode=build cần args.components[] từ blueprint ĐÃ ĐƯỢC USER DUYỆT. Không chạy trước cổng duyệt GĐ3.' }
  const FILE_SCHEMA = {
    type: 'object', required: ['filename', 'content', 'notes'],
    properties: {
      filename: { type: 'string', description: 'tên file đề xuất (không ghi đường dẫn tuyệt đối)' },
      content: { type: 'string', description: 'nội dung file hoàn chỉnh, LF, tiếng Việt có dấu' },
      notes: { type: 'string', description: 'giả định/điểm cần user quyết; chuỗi rỗng nếu không có' },
    },
  }
  const REVIEW_SCHEMA = {
    type: 'object', required: ['pass', 'violations', 'evidence'],
    properties: { pass: { type: 'boolean' }, violations: { type: 'array', items: { type: 'string' } }, evidence: { type: 'string' } },
  }
  const specPath = 'C:/Users/Admin/.claude/skills/foxai-agent-factory/templates/agent-spec.md'
  const results = await pipeline(
    a.components,
    (c) => agent(`Bạn là builder trong agent-factory FOXAI. Viết NỘI DUNG file cho component sau (KHÔNG ghi file — chỉ trả về content qua schema):
Loại: ${c.type} (agent .md | workflow .js | skill SKILL.md | eval .md) · Tên: ${c.name}
Spec từ blueprint đã duyệt: ${c.spec}
${a.blueprintPath ? `Đọc blueprint đầy đủ bằng Read: ${a.blueprintPath}` : ''}
Chuẩn bắt buộc: đọc ${specPath} và tuân thủ (agent .md: frontmatter + kỷ luật Fable + format đầu ra; workflow .js: parse args phòng thủ string/object, schema structured output, guard chặn chạy trước cổng duyệt, KHÔNG dùng Date.now/Math.random). Trả về đúng schema.`,
      { label: `build:${c.name}`, phase: 'Build', schema: FILE_SCHEMA }),
    (draft, c) => !draft ? null :
      agent(`Bạn là reviewer độc lập (không tin builder). Đọc checklist cuối file ${specPath} và đối chiếu file dưới đây với spec: "${c.spec}".
Kiểm: frontmatter hợp lệ? tools tối thiểu? có đủ 3 mục kỷ luật Fable? hành vi cấm có mặt? workflow có guard + parse args phòng thủ? Thiếu bất kỳ mục checklist nào = pass:false.
--- FILE ${c.name} ---
${draft.content}
--- HẾT ---`,
        { label: `review:${c.name}`, phase: 'Review', schema: REVIEW_SCHEMA })
        .then(v => ({ component: c.name, type: c.type, draft, review: v })),
  )
  const done = results.filter(Boolean)
  const passed = done.filter(r => r.review && r.review.pass)
  log(`Build xong: ${passed.length}/${a.components.length} component PASS review`)
  return { mode: 'build',
    summary: { total: a.components.length, passed: passed.length, failed: done.filter(r => !r.review || !r.review.pass).map(r => r.component) },
    components: done,
    next_steps: 'Main loop: sửa component FAIL theo review → GHI FILE (LF!) → cài vào project đích → GĐ5: smoke test + EVAL canary + gọi foxai-factory-verifier.' }
}

return { error: `mode "${a.mode}" không hỗ trợ — chỉ "design" | "build".` }
