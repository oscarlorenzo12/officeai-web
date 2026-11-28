import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
const plain=(s:string,status=200)=>new Response(s,{status,headers:{"content-type":"text/plain; charset=utf-8","cache-control":"no-store"}});
const verifyToken=Deno.env.get("META_WEBHOOK_VERIFY_TOKEN");
const appSecret=Deno.env.get("META_APP_SECRET");
const dbUrl=Deno.env.get("SUPABASE_URL");
const serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
async function signatureOk(raw:string,header:string) {
 if(!appSecret||!/^sha256=[a-f0-9]{64}$/i.test(header))return false;
 const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(appSecret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);
 const digest=new Uint8Array(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(raw)));
 const expected="sha256="+Array.from(digest).map(x=>x.toString(16).padStart(2,"0")).join("");
 let mismatch=expected.length^header.length;
 for(let i=0;i<expected.length;i++)mismatch|=expected.charCodeAt(i)^header.toLowerCase().charCodeAt(i);
 return mismatch===0;
}
Deno.serve(async req=>{
 if(req.method==="GET"){
  if(!verifyToken)return plain("Not configured",503);
  const url=new URL(req.url);
  const ok=url.searchParams.get("hub.mode")==="subscribe"&&url.searchParams.get("hub.verify_token")===verifyToken;
  const challenge=url.searchParams.get("hub.challenge")||"";
  return ok&&/^\d{1,40}$/.test(challenge)?plain(challenge):plain("Forbidden",403);
 }
 if(req.method!=="POST")return plain("Method not allowed",405);
 if(!appSecret||!dbUrl||!serviceKey)return plain("Not configured",503);
 const raw=await req.text();
 if(raw.length>1024*1024)return plain("Too large",413);
 if(!await signatureOk(raw,req.headers.get("x-hub-signature-256")||""))return plain("Unauthorized",401);
 let payload:any;
 try{payload=JSON.parse(raw)}catch{return plain("Invalid JSON",400)}
 if(payload?.object!=="whatsapp_business_account")return plain("Ignored",200);
 const db=createClient(dbUrl,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
 for(const entry of payload.entry||[])for(const change of entry.changes||[]){
  if(change.field!=="messages")continue;
  const phone=String(change.value?.metadata?.phone_number_id||"");
  if(!phone)continue;
  const {data:channel,error:ce}=await db.from("officeai_whatsapp_channels").select("organization_id,service_instance_id").eq("meta_phone_number_id",phone).eq("enabled",true).maybeSingle();
  if(ce)return plain("Storage error",500);
  if(!channel)continue;
  for(const event of change.value?.statuses||[]){
   if(!event?.id||!["sent","delivered","read","failed"].includes(event.status)||!/^\d{1,10}$/.test(String(event.timestamp||"")))continue;
   const at=new Date(Number(event.timestamp)*1000);
   if(!Number.isFinite(at.getTime()))continue;
   const {error:de}=await db.rpc("officeai_whatsapp_record_delivery_event",{p_phone_id:phone,p_message_id:String(event.id),p_status:event.status,p_at:at.toISOString()});
   if(de)return plain("Storage error",500);
  }
  for(const m of change.value?.messages||[]){
   if(!m?.id||!m?.from)continue;
   const msg={organization_id:channel.organization_id,service_instance_id:channel.service_instance_id,meta_message_id:String(m.id),sender_wa_id:String(m.from),message_text:m.type==="text"?String(m.text?.body||"").slice(0,10000):"[mensaje no textual]",direction:"inbound"};
   const {error:e}=await db.from("officeai_whatsapp_messages").upsert(msg,{onConflict:"meta_message_id",ignoreDuplicates:true});
   if(e)return plain("Storage error",500);
  }
 }
 return plain("EVENT_RECEIVED",200);
});