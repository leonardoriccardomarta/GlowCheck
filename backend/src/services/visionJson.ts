export function extractVisionJson(text: string): string | null {
  let body = text.replace(/<think>[\s\S]*?<\/think>/gi, ' ');
  body = body.replace(/<thinking>[\s\S]*?<\/thinking>/gi, ' ');
  body = body.trim();
  const fenced = body.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenced) body = fenced[1].trim();
  const start = body.indexOf('{');
  const end = body.lastIndexOf('}');
  if (start === -1 || end <= start) return null;
  return body.slice(start, end + 1);
}
