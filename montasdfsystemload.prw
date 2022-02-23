#INCLUDE "TOTVS.CH"

// https://github.com/amjgfarias/advpl-nordesteatacado.git
/*/{Protheus.doc} MontaSDF
Programa para gerar os arquivos sdfbra.txt e hlpdfpor.txt organizadamente em uma pasta systemload para facilitar a aplicação do upddistr
@type Function
@author alessandro@farias.net.br
@since 22/02/2022
@version 1.0
@example U_MontaSDF
/*/

****** Esse fonte é o 1o passo de um projeto meu para atualizacao continua de dicionarios via upddistr sem interacao nenhuma.
****** no final deste fonte contem algumas informacoes para execucao do updistr via job.

/*
a pasta lixo é a pasta onde ficará todos os pacotes do portal da totvs.
a pasta tmpzip é a o local temporario para criacao dos pacotes systemload separado por arquivo expedicao continua da totvs.
*/

User Function MontaSDF
Local aDir1 := Directory("c:\lixo\*.zip","A")
Local ndir1
For ndir1:=1 To Len(aDir1)
	u_FListZip(aDir1[ndir1][1],"c:\lixo\")
Next ndir1
Return

User Function FListZip(cFile,cOrigem)
Local nret := 10
Local aRet := {}
Local cDestino
Local ndir1,ndir2,ndir3
Local cDrive, cDir, cNome, cExt
Local aDir1 := {}
Local aDir2 := {}
Local aDir3 := {}
cFile  := lower(NoAcento(cFile))
FwMakeDir("c:\tmpzip\")
__CopyFile( cOrigem + cFile, "c:\tmpzip\"+cFile )
SplitPath( "C:\tmpzip\"+cFile, @cDrive, @cDir, @cNome, @cExt )
cDestino := cDrive + cDir + cNome
aRet := FListZip("C:\tmpzip\"+cFile,nret)
if nret == 0
	FwMakeDir(cDrive + cDir + cNome)
	nret := FUnzip(cDrive + cDir + cNome + cExt, cDestino )
	if nret == 0
		aDir1 := Directory(cDestino+"\*.*","D")
		For ndir1:=1 To Len(aDir1)
			If "SDF" $ upper(aDir1[ndir1][1])
				cDest1 := cDestino+"\"+aDir1[ndir1][1]
				aDir2 := Directory(cDest1+"\*.*","D")
				For ndir2:=1 To Len(aDir2)
					cDest2 := cDest1+"\"+aDir2[ndir2][1]
					If "BRA" $ upper(aDir2[ndir2][1])
						cDest3 := cDest2+"\"
						aDir3 := Directory(cDest2+"\*.txt","A")
						For ndir3:=1 To Len(aDir3)
							If "SDFBRA.TXT" $ upper(aDir3[ndir3][1]) .Or. "HLPDFPOR.TXT" $ upper(aDir3[ndir3][1])
								FwMakeDir( "c:\tmpzip\systemload\"+cNome )
								__CopyFile( cDest3+aDir3[ndir3][1], "c:\tmpzip\systemload\"+cNome+"\"+aDir3[ndir3][1] )
							Endif
						Next ndir3
					Endif
				Next ndir2
			Endif
		Next ndir1
	Endif
endif
Return

/*
[UPDJOB]
MAIN=UPDDISTR
ENVIRONMENT=P12

[ONSTART]
Jobs=UPDJOB
RefreshRate=900

2. Na pasta Systemload, crie um arquivo JSON chamado upddistr_param.json, com o seguinte conteúdo:

{
"password":"senha",
"simulacao":false,
"localizacao":"BRA",
"sixexclusive":true,
"empresas":["99","01","03"],
"logprocess":false,
"logatualizacao":false,
"logwarning":false,
"loginclusao":false,
"logcritical":true,
"updstop":false,
"oktoall":true,
"deletebkp":true,
"keeplog":false
}

password = Senha do usuário administrador
simulacao = Habilita o modo simulação, onde nenhuma modificação é efetivada
localizacao = País que deve ser utilizado
sixexclusive = Utilizar o arquivo de índices por empresa
empresas = Lista das empresas que serão migradas, separadas por vírgula
logprocess = Log de Processo
logatualizacao = Log de Atualização
logwarning = Log de Warning Error
loginclusao = Log de Inclusão
logcritical = Log de Critical Error
updstop = Permite interromper processo durante execução
oktoall = Corrigir error automaticamente
deletebkp = Eliminar arquivos de backup ao término da atualização de cada tabela
keeplog = Manter o arquivo de log existente

 */
