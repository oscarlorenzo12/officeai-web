import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
const pages=['index','incorporacion','recepcion-bandeja','recepcion-cliente','officeai-whatsapp-v3','contactos','presupuestos','assistant-connected','contratos','finanzas','facturacion','requests','tarifas','ventas'];
let failures=0;
for(const page of pages){
 const html=readFileSync(new URL('../'+page+'.html',import.meta.url),'utf8');
 const scripts=[...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)].filter(m=>! /\bsrc\s*=/.test(m[1]));
 if(!scripts.length){console.error(page+': no inline scripts');failures++;continue;}
 for(const [,attrs,source] of scripts){
 const result=spawnSync(process.execPath,['--check','--input-type='+(/type\s*=\s*["']module["']/i.test(attrs)?'module':'commonjs')],{input:source,encoding:'utf8'});
 if(result.status!==0){failures++;console.error(page+': '+(result.stderr||result.error||'check failed'));}else console.log(page+': OK');
 }
}
process.exitCode=failures?1:0;
