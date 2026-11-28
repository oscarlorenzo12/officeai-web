import "jsr:@supabase/functions-js/edge-runtime.d.ts";
type State={intent?:"appointment"|"quote";step?:"service"|"date"|"contact"|"details";service?:string;date?:string;details?:string};
const cors={"Access-Control-Allow-Origin":"https://oscarlorenzo12.github.io","Access-Control-Allow-Headers":"authorization,apikey,content-type,x-client-info,x-supabase-client-platform,x-supabase-client-platform-version,x-supabase-client-runtime,x-supabase-client-runtime-version","Access-Control-Allow-Methods":"POST,OPTIONS","Vary":"Origin"};
const respond=(x:unknown,s=200)=>new Response(JSON.stringify(x),{status:s,headers:{...cors,"content-type":"application/json","cache-control":"no-store"}});
const norm=(x:string)=>x.normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();
function process(message:string,old:State={},business="el negocio",info:any={}){
 const state:State={};if(old&&typeof old==="object"){if(old.intent==="appointment"||old.intent==="quote")state.intent=old.intent;if(["service","date","contact","details"].includes(old.step||""))state.step=old.step;if(typeof old.service==="string")state.service=old.service.slice(0,200);if(typeof old.date==="string")state.date=old.date.slice(0,120);if(typeof old.details==="string")state.details=old.details.slice(0,300)}
 const t=norm(message);let intent=state.intent||"general";let reply="",ready=false,handoff=false;
 if(/\b(cancelar|reiniciar|empezar de nuevo)\b/.test(t)){return {reply:"De acuerdo, empezamos de nuevo. ¿Necesitas una cita o un presupuesto?",intent:"reset",state:{},ready:false,handoff:false}}
 if(/\b(persona|humano|empleado|reclamacion|queja)\b/.test(t)){return {reply:"Esta consulta necesita atención humana. La demostración no ha enviado ningún aviso.",intent:"handoff",state:{},ready:false,handoff:true}}
 if(/\b(horario|horarios|abris|abren|cerrais|cierran|direccion|ubicacion)\b|donde est/.test(t)){const hours=typeof info?.hours==="string"?info.hours.slice(0,300):"";const address=typeof info?.address==="string"?info.address.slice(0,300):"";const wantedHours=/(horario|abri|cerr)/.test(t);return {reply:wantedHours?(hours?"Horario facilitado por el negocio: "+hours:"No tengo el horario confirmado. Consulta directamente con el negocio."):(address?"Dirección facilitada por el negocio: "+address:"No tengo la dirección confirmada."),intent:"business_info",state,ready:false,handoff:false,submitted:false}}
 if(!state.intent){if(/cita|reserv|agendar/.test(t)){state.intent="appointment";state.step="service";intent="appointment";reply="¿Para qué servicio quieres solicitar una cita o reserva?"}
 else if(/presupuest|precio|cotizacion/.test(t)){state.intent="quote";state.step="service";intent="quote";reply="¿Sobre qué servicio necesitas el presupuesto?"}
 else if(/hola|buenas/.test(t)){reply="Hola, soy el asistente de "+business+". ¿Necesitas una cita o un presupuesto?"}
 else{reply="Puedo ayudarte a preparar una cita o una solicitud de presupuesto. ¿Cuál necesitas?"}}
 else if(state.step==="service"){state.service=message.slice(0,200);state.step=state.intent==="appointment"?"date":"details";reply=state.intent==="appointment"?"¿Qué fecha y hora prefieres? La disponibilidad se confirmará después.":"Describe brevemente qué necesitas para el presupuesto."}
 else if(state.step==="date"){state.date=message.slice(0,120);state.step="contact";reply="¿Qué nombre y medio de contacto quieres facilitar? No compartas datos sensibles."}
 else if(state.step==="details"){state.details=message.slice(0,300);state.step="contact";reply="¿Qué nombre y medio de contacto quieres facilitar? No compartas datos sensibles."}
 else if(state.step==="contact"){intent=state.intent;ready=true;handoff=true;reply="Solicitud preparada para revisión humana. Esta demo no guarda datos, no envía mensajes ni confirma reservas o presupuestos.";return {reply,intent,state:{...state,contact:message.slice(0,200)},ready,handoff,submitted:false}}
 return {reply,intent,state,ready,handoff,submitted:false};
}
Deno.serve(async req=>{
 if(req.method==="OPTIONS")return new Response(null,{status:204,headers:cors});
 if(req.method!=="POST")return respond({error:"Method not allowed"},405);
 if(!(req.headers.get("content-type")||"").includes("application/json"))return respond({error:"JSON required"},415);
 if(Number(req.headers.get("content-length")||0)>10000)return respond({error:"Too large"},413);
 let body:any;try{const reader=req.body?.getReader();if(!reader)return respond({error:"Invalid JSON"},400);const decoder=new TextDecoder();let size=0,raw="";while(true){const {done,value}=await reader.read();if(done)break;size+=value.byteLength;if(size>10000){await reader.cancel();return respond({error:"Too large"},413)}raw+=decoder.decode(value,{stream:true})}raw+=decoder.decode();body=JSON.parse(raw)}catch{return respond({error:"Invalid JSON"},400)}
 if(body?.self_test===true){const a=process("Quiero una cita");const b=process("Revisión de coche",a.state);const c=process("jueves a las 10",b.state);const d=process("Cliente de prueba",c.state);const q=process("Necesito presupuesto");return respond({passed:a.intent==="appointment"&&b.state.step==="date"&&c.state.step==="contact"&&d.ready&&q.intent==="quote",scenarios:["appointment","multiturn","quote"],mode:"free_rules"})}
 const message=typeof body?.message==="string"?body.message.trim():"";if(!message||message.length>2000)return respond({error:"Message must contain 1-2000 characters"},400);
 return respond({...process(message,body.state,typeof body.business_name==="string"?body.business_name.slice(0,80):"el negocio",body.business_info),mode:"free_rules",external_ai:false,sent:false,persisted:false});
});