import { revalidatePath } from 'next/cache';
import { NextRequest, NextResponse } from 'next/server';

// API route for on-demand revalidation
// Usage: POST /api/revalidate?path=/yellow-books&secret=YOUR_SECRET
export async function POST(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const path = searchParams.get('path');
  const secret = searchParams.get('secret');
  
  // Validate secret token
  const revalidateSecret = process.env.REVALIDATE_SECRET || 'dev-secret-token';
  
  if (secret !== revalidateSecret) {
    return NextResponse.json(
      { message: 'Invalid secret token' },
      { status: 401 }
    );
  }
  
  if (!path) {
    return NextResponse.json(
      { message: 'Path parameter is required' },
      { status: 400 }
    );
  }
  
  try {
    revalidatePath(path);
    
    return NextResponse.json({
      success: true,
      message: `Revalidated path: ${path}`,
      revalidated: true,
      now: Date.now(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        success: false,
        message: 'Error revalidating',
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
