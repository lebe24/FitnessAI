# Supabase Edge Function: delete-user

This Edge Function is required for the delete account functionality. It handles user deletion server-side using the service role key.

## Setup Instructions

1. **Create the Edge Function in Supabase Dashboard:**
   - Go to your Supabase project dashboard
   - Navigate to Edge Functions
   - Create a new function named `delete-user`

2. **Deploy the following code:**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create a Supabase client with the service role key
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get the user ID from the request body
    const { userId } = await req.json()

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'User ID is required' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Verify the requesting user is authenticated and matches the userId
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Get the current user from the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError || !user || user.id !== userId) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: User ID mismatch' }),
        { 
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Delete the user using admin API
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteError) {
      return new Response(
        JSON.stringify({ error: deleteError.message }),
        { 
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    return new Response(
      JSON.stringify({ success: true, message: 'User deleted successfully' }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
```

3. **Deploy the function:**
   - Save the code in the Supabase dashboard
   - Deploy the function

4. **Environment Variables:**
   - The function will automatically use `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from your project settings
   - These are available by default in Edge Functions

## Alternative: Using Supabase CLI

If you prefer using the CLI:

```bash
# Create the function
supabase functions new delete-user

# Add the code to supabase/functions/delete-user/index.ts

# Deploy
supabase functions deploy delete-user
```

## Security Notes

- The Edge Function uses the service role key server-side only
- It verifies that the requesting user matches the userId being deleted
- Never expose the service role key in client-side code
- The function includes proper CORS headers for web compatibility

























