// Supabase Edge Function: recalculate_priority
// Deploy with: supabase functions deploy recalculate_priority

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  const { complaintId } = await req.json()
  if (!complaintId) {
    return new Response(JSON.stringify({ error: 'complaintId is required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const { data, error } = await supabase.rpc('recalculate_priority', {
    p_complaint_id: complaintId,
  })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ priorityScore: data }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
