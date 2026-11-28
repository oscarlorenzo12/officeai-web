import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {createClient} from "npm:@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"https://oscarlorenzo12.github.io","Access-Control-Allow-Headers":"authorization, apikey, content-type, x-client-info, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version","Access-Control-Allow-Methods":"POST, OPTIONS","Content-Type":"application/json"};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:cors});
Deno.serve(async(req)=>{
 if(req.method==="OPTIONS")return new Response(null,{headers:cors});
 if(req.method!=="POST")return reply({error:"Método no permitido"},405);
 try{
 const auth=req.headers.get("Authorization")||"";
 if(!auth.startsWith("Bearer "))return reply({error:"Inicia sesión"},401);
 const url=Deno.env.get("SUPABASE_URL")||"",key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"";
 if(!url||!key)return reply({error:"Servicio no configurado"},503);
 const db=createClient(url,key,{auth:{persistSession:false}});
 const {data:{user},error:ue}=await db.auth.getUser(auth.slice(7));
 if(ue||!user)return reply({error:"Sesión no válida"},401);
 const body=await req.json().catch(()=>null);
 const requestId=String(body?.request_id||"");
 const instance=String(body?.instance_id||""),to=String(body?.to||""),message=String(body?.message||"").trim();
 if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(requestId)||!/^[0-9a-f-]{36}$/i.test(instance)||!/^[1-9][0-9]{7,14}$/.test(to)||!message||message.length>4096)return reply({error:"Datos de envío no válidos"},400);
 const {data:channel,error:ce}=await db.from("officeai_whatsapp_channels").select("organization_id,service_instance_id,meta_phone_number_id").eq("service_instance_id",instance).eq("enabled",true).maybeSingle();
 if(ce||!channel)return reply({error:"Canal no disponible"},404);
 const {data:member}=await db.from("organization_members").select("role").eq("organization_id",channel.organization_id).eq("user_id",user.id).maybeSingle();
 if(!member)return reply({error:"Sin permisos para este negocio"},403);
 const {data:latest}=await db.from("officeai_whatsapp_messages").select("received_at").eq("service_instance_id",instance).eq("sender_wa_id",to).eq("direction","inbound").order("received_at",{ascending:false}).limit(1).maybeSingle();
 if(!latest||Date.now()-new Date(latest.received_at).getTime()>24*60*60*1000)return reply({error:"Fuera de la ventana de 24 horas: no se permite texto libre"},409);
 const token=Deno.env.get("META_WHATSAPP_ACCESS_TOKEN");
 if(!token)return reply({error:"Falta configurar META_WHATSAPP_ACCESS_TOKEN en Supabase; no se ha enviado nada"},503);
 const {error:attemptError}=await db.from("officeai_whatsapp_send_attempts").insert({service_instance_id:instance,request_id:requestId,created_by:user.id});
 if(attemptError)return reply({error:attemptError.code==="23505"?"Intento ya registrado. Revisa el historial antes de repetir.":"No se pudo reservar el intento; no se ha enviado nada"},409);
 const mark=async(status:string,diagnostics:Record<string,number|null>={})=>await db.from("officeai_whatsapp_send_attempts").update({status,...diagnostics}).eq("service_instance_id",instance).eq("request_id",requestId);
 try{
 const response=await fetch("https://graph.facebook.com/v23.0/"+encodeURIComponent(channel.meta_phone_number_id)+"/messages",{method:"POST",headers:{"Authorization":"Bearer "+token,"Content-Type":"application/json"},body:JSON.stringify({messaging_product:"whatsapp",to,type:"text",text:{body:message}})});
 const result=await response.json().catch(()=>({}));
 if(!response.ok||!result?.messages?.[0]?.id){const code=Number.isSafeInteger(result?.error?.code)?result.error.code:null;const sub=Number.isSafeInteger(result?.error?.error_subcode)?result.error.error_subcode:null;await mark("uncertain",{meta_http_status:response.status,meta_error_code:code,meta_error_subcode:sub});const diagnostic="Meta HTTP "+response.status+(code!==null?" · código "+code:"")+(sub!==null?" · subcódigo "+sub:"");console.warn("WhatsApp send diagnostic",diagnostic);return reply({error:diagnostic+". Resultado no confirmado. Revisa el historial antes de repetir."},502);}
 const id=String(result.messages[0].id); await mark("accepted");
 const {error:se}=await db.from("officeai_whatsapp_messages").upsert({organization_id:channel.organization_id,service_instance_id:instance,meta_message_id:id,sender_wa_id:to,message_text:message,direction:"outbound"},{onConflict:"meta_message_id",ignoreDuplicates:true});
 return reply({success:true,message_id:id,stored:!se,warning:se?"Meta aceptó el mensaje, pero no pudo guardarse":undefined});
 }catch{await mark("uncertain");return reply({error:"Resultado incierto. Revisa el historial antes de repetir."},502)}
 }catch{return reply({error:"No se pudo procesar la solicitud"},500)}
});