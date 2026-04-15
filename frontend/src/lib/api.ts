const DIRECTUS_URL = import.meta.env.DIRECTUS_INTERNAL_URL || 'http://localhost:8055';
const PUBLIC_URL = import.meta.env.PUBLIC_DIRECTUS_URL || 'http://localhost:8055';

export interface Teaching {
  id: number;
  status: string;
  title: string;
  description: string | null;
  category: string | null;
  date_published: string | null;
  file: FileItem | null;
}

export interface FileItem {
  id: string;
  title: string;
  filename_download: string;
  type: string;
  filesize: number;
}

export async function getTeachings(): Promise<Teaching[]> {
  try {
    const res = await fetch(
      `${DIRECTUS_URL}/items/teachings?filter[status][_eq]=published&fields=*,file.*&sort=-date_published`
    );
    if (!res.ok) return [];
    const data = await res.json();
    return data.data ?? [];
  } catch {
    return [];
  }
}

export async function getTeaching(id: string): Promise<Teaching | null> {
  try {
    const res = await fetch(
      `${DIRECTUS_URL}/items/teachings/${id}?fields=*,file.*`
    );
    if (!res.ok) return null;
    const data = await res.json();
    return data.data ?? null;
  } catch {
    return null;
  }
}

export function fileUrl(fileId: string): string {
  return `${PUBLIC_URL}/assets/${fileId}`;
}

export function downloadUrl(fileId: string): string {
  return `${PUBLIC_URL}/assets/${fileId}?download`;
}

export function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function categoryLabel(cat: string | null): string {
  const labels: Record<string, string> = {
    lecture: 'Lecture',
    presentation: 'Presentation',
    document: 'Document',
    other: 'Other',
  };
  return cat ? labels[cat] ?? cat : 'Uncategorized';
}

export function fileIcon(type: string | null): string {
  if (!type) return '📄';
  if (type.includes('pdf')) return '📕';
  if (type.includes('presentation') || type.includes('ppt')) return '📊';
  if (type.includes('word') || type.includes('doc')) return '📝';
  if (type.includes('spreadsheet') || type.includes('excel')) return '📗';
  return '📄';
}
