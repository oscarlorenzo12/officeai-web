import {createClient} from "npm:@supabase/supabase-js@2.57.0";
const cors={"Access-Control-Allow-Origin":"https://oscarlorenzo12.github.io","Access-Control-Allow-Headers":"authorization,apikey,content-type,x-client-info","Access-Control-Allow-Methods":"POST,OPTIONS","Vary":"Origin"};
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{...cors,"Content-Type":"application/json","Cache-Control":"no-store"}});
Deno.serve(async(req)=>{
if(req.method==="OPTIONS")return new Response(null,{status:204,headers:cors});
if(req.method!=="POST")return reply({error:"Método no permitido"},405);
try{
const reader=req.body?.getReader();if(!reader)return reply({error:"Solicitud vacía"},400);
let size=0;const decoder=new TextDecoder();let raw="";
while(true){const {done,value}=await reader.read();if(done)break;size+=value.byteLength;if(size>5000){await reader.cancel();return reply({error:"Solicitud demasiado larga"},413);}raw+=decoder.decode(value,{stream:true});}raw+=decoder.decode();
const b=JSON.parse(raw);const id=b.instance_id;
if(typeof id!=="string"||!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id))return reply({error:"Recepcionista no disponible"},404);
const url=Deno.env.get("SUPABASE_URL")!,key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const sb=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
const {data:i,error}=await sb.from("service_instances").select("business_hours,location_text,faq,business_name,privacy_notice_url").eq("id",id).eq("public_enabled",true).maybeSingle();
if(error||!i||!i.privacy_notice_url)return reply({error:"Recepcionista no disponible"},404);
if(b.action==="info")return reply({business_name:i.business_name,privacy_notice_url:i.privacy_notice_url});
if(b.action==="answer"){const q=typeof b.question==="string"?b.question.trim().toLowerCase():"";if(!q||q.length>500)return reply({error:"Consulta no válida"},400);const norm=(s:string)=>s.normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase().trim();const match=Array.isArray(i.faq)?i.faq.find((f:any)=>typeof f?.question==="string"&&typeof f?.answer==="string"&&norm(f.question)===norm(q)):null;return reply({answer:match?.answer||(/horario|abren|abierto/.test(q)?i.business_hours:/dirección|ubicación|dónde/.test(q)?i.location_text:"")||"El equipo debe revisar tu consulta.",appointment_confirmed:false});}
if(b.action==="availability"){
if(typeof b.date!=="string"||!/^\d{4}-\d{2}-\d{2}$/.test(b.date)||typeof b.time!=="string"||!/^\d{2}:\d{2}$/.test(b.time)||!Number.isSafeInteger(b.guests)||b.guests<1||b.guests>100000)return reply({error:"Consulta no válida"},400);
const {data,error}=await sb.rpc("officeai_public_reservation_check",{p_instance:id,p_date:b.date,p_time:b.time,p_guests:b.guests});
if(error)return reply({error:"No se pudo consultar la disponibilidad"},400);
if(!["available","full","closed","outside_hours","manual","invalid","unavailable"].includes(data))return reply({error:"Disponibilidad no verificable"},503);
return reply({availability:data,appointment_confirmed:false});
}
if(b.action==="reservation"){
if(b.consent!==true||typeof b.name!=="string"||typeof b.phone!=="string"||typeof b.date!=="string"||!/^\d{4}-\d{2}-\d{2}$/.test(b.date)||typeof b.time!=="string"||!/^\d{2}:\d{2}$/.test(b.time)||!Number.isSafeInteger(b.guests)||b.guests<1||b.guests>2147483647||(b.note!=null&&typeof b.note!=="string"))return reply({error:"Reserva no válida"},400);
const {data,error}=await sb.rpc("officeai_public_reservation",{p_instance:id,p_name:b.name,p_phone:b.phone,p_date:b.date,p_time:b.time,p_guests:b.guests,p_note:b.note??""});
if(error)return reply({error:"No se pudo registrar la reserva"},error.message.includes("Límite temporal")?429:400);
return reply({ok:true,request_id:data,status:"pending",appointment_confirmed:false});
}
if(b.action==="intake"){const note=typeof b.note==="string"?b.note.trim():"";if(!["information","appointment","callback"].includes(b.request_type)||!["morning","afternoon","any"].includes(b.preferred_slot)||!note||note.length>1000||b.consent!==true)return reply({error:"Solicitud no válida"},400);
const {data,error}=await sb.rpc("officeai_public_intake",{p_instance_id:id,p_request_type:b.request_type,p_preferred_slot:b.preferred_slot,p_note:note});if(error)return reply({error:"No se pudo registrar la solicitud"},error.message.includes("Límite temporal")?429:400);return reply({ok:true,request_id:data,status:"pending",appointment_confirmed:false});}
return reply({error:"Acción no permitida"},400);
}catch{return reply({error:"Solicitud no válida"},400);}
});