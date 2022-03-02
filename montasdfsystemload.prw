#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"

Static __cConsoleLg	:= GetPvProfString("GENERAL", "ConsoleFile", "console.log", GetAdv97())
Static __cSystemload	:= "\systemload\"
Static __cServerPath	:= lower(GetPvProfString(GetEnvServer(),"APPSERVER","ERRO",GetADV97()))
Static __lInDB			:= .F.


/*/{Protheus.doc} MontaSDF
Programa para gerar os arquivos sdfbra.txt e hlpdfpor.txt organizadamente em uma pasta systemload para facilitar a aplicação do upddistr
@type Function
@author alessandro@farias.net.br
@since 22/02/2022
@version 1.0
@example U_MontaSDF
/*/
User Function MontaSDF

	Local cOrigem  := ""
	Local cDestino := ""
	Local cEmpresas:= ""
	Local aDir1    := {}
	Local ndir1
	Local aSM0 		:= {}
	Local aFill		:= {}
	Local aLogin	:= {}

	****************** lembrar de rodar -> FwRebuildIndex

	// criar tela para o analista informar o caminho + nome completo do appserver para aplicacao de ptm
	If __cServerPath	== "erro"
		WriteSrvProfString("APPSERVER", "c:\r33\protheus\bin\appserver\appserver.exe")
		__cServerPath	:= lower(GetPvProfString(GetEnvServer(),"APPSERVER","ERRO",GetADV97()))
	Endif

	//OpenSM0Excl() //Realiza a abertura do dicionario Exclusivo para validar se ha alguem acessando
	//RpcClearEnv()

	FwMakeDir("c:\tmpzip\")

	aLogin := DistrLogin()

	aSM0  := GetSM0()
	aFill := GetFill(aSM0[01])

	cEmpresas := ToBrackets(ArrTokStr(aSM0,","),',')

	cOrigem := cGetFile('*.*', "Diretorio dos pacotes", 1, "c:\tmpzip\", .F., GETF_RETDIRECTORY+GETF_NETWORKDRIVE+GETF_LOCALHARD)
	cDestino := cGetFile('*.*', "Diretorio dos pacotes", 1, "c:\tmpzip\", .F., GETF_RETDIRECTORY+GETF_NETWORKDRIVE+GETF_LOCALHARD)

	// sou obrigado a dar um rpc em qualquer empresa para ter acesso ao \systemload\ para excluir os aquivos "lixo" e copia o .json
	RpcClearEnv()
	If ! RpcSetEnv(aSM0[01],aFill[01],aLogin[01],aLogin[02],"CFG","U_PBDISTRR")
		Final("Erro ao efetuar teste de acesso!")
	Endif

	__lInDB		:= MPDicInDB()

	// limpeza inicial antes de executar o 1o pacote
	CleanSystemLoad()

	If File(__cSystemload+"upddistr_param.json")
		fErase(__cSystemload+"upddistr_param.json")
	Endif

	// ja cria o arquivo na pasta systemload
	MakeJson(__cSystemload,aLogin[02],aSM0)

	RpcClearEnv() // todas as tabelas devem estar fechadas senao o job do upddistr nao irá rodar

	ConOut("local do console.log -> "+__cConsoleLg)
	
	//cOrigem  := SuperGetMV("MV_XORIGEM" ,.F.,"c:\patch_totvs\")
	//cDestino := SuperGetMV("MV_XDESTINO",.F.,"c:\tmpzip\")
	
	FwMakeDir(cDestino)
	FwMakeDir(cOrigem + "processado\")
	FwMakeDir(cOrigem + "pendente\")
	FwMakeDir(cOrigem + "erro\")

	aDir1 := Directory(cOrigem + "*.zip","A")
	
	For ndir1 := 1 To Len(aDir1)
		
		//se retornar erro sai do pacote e copia os arquivos pendentes para a pasta não processados
		if xListZip(aDir1[ndir1][1], cOrigem, cDestino)
			if __CopyFile( cOrigem + aDir1[ndir1][1], cOrigem + "processado\" + aDir1[ndir1][1] )
				fErase(cOrigem + aDir1[ndir1][1])
			endif
		else
			if __CopyFile( cOrigem + aDir1[ndir1][1], cOrigem + "erro\" + aDir1[ndir1][1] )
				fErase(cOrigem + aDir1[ndir1][1])
			endif
			aEval(Directory(cOrigem + "\sdfbra.txt"), { |aFile| __CopyFile( cOrigem +aFile[1] , cOrigem + "pendente\" + aFile[1]) })
			aEval(Directory(cOrigem + "\hlpdfpor.txt"), { |aFile| __CopyFile( cOrigem +aFile[1] , cOrigem + "pendente\" + aFile[1]) })
			ndir1 := Len(aDir1)
		endif
		
	Next ndir1

	If File(__cSystemload+"upddistr_param.json")
		fErase(__cSystemload+"upddistr_param.json")
	Endif

	RpcClearEnv()
	RpcSetEnv(aSM0[01],aFill[01],aLogin[01],aLogin[02],"CFG","U_PBDISTRR")

Return


/*/{Protheus.doc} XListZip
Função para descompactar o arquivo zip na pasta temporaria
@type function
@version 1.0
@author Ulisses Souza
@since 22/02/2022
@param cFile, character, Arquivo origem
@param cOrigem, character, Diretório de Origem
@param cDestino, character, Diretório Destino
/*/
Static Function XListZip(cFile, cOrigem, cDestinoOri)

	Local nret := 10
	Local aRet := {}
	Local ndir1 , ndir2 , ndir3
	Local cDrive, cDir  , cNome, cExt
	Local aDir1 := {}
	Local aDir2 := {}
	Local aDir3 := {}
	
	cFile  := lower(NoAcento(cFile))
	
	FwMakeDir(cDestinoOri)
	__CopyFile( cOrigem + cFile, cDestinoOri + cFile )
	
	SplitPath( cDestinoOri + cFile, @cDrive, @cDir, @cNome, @cExt )
	
	aRet := FListZip(cDestinoOri + cFile,nret)
	
	if nret == 0
		
		FwMakeDir(cDrive + cDir + cNome)
		
		cDestino := cDrive + cDir + cNome
		
		nret := FUnzip(cDrive + cDir + cNome + cExt, cDestino )
		
		if nret == 0
			aDir1 := Directory(cDestino+"\*.*","D")
			For ndir1 := 1 To Len(aDir1)
				
				If "SDF" $ upper(aDir1[ndir1][1])
					cDest1 := cDestino+"\"+aDir1[ndir1][1]
					aDir2 := Directory(cDest1+"\*.*","D")
					
					For ndir2 := 1 To Len(aDir2)
						cDest2 := cDest1+"\"+aDir2[ndir2][1]
						
						If "BRA" $ upper(aDir2[ndir2][1])
							cDest3 := cDest2+"\"
							aDir3 := Directory(cDest2+"\*.txt","A")
							
							For ndir3 := 1 To Len(aDir3)
								If "SDFBRA.TXT" $ upper(aDir3[ndir3][1]) .Or. "HLPDFPOR.TXT" $ upper(aDir3[ndir3][1])
									FwMakeDir( cDestinoOri + "systemload\" )
									__CopyFile( cDest3+aDir3[ndir3][1], cDestinoOri + "systemload\"+aDir3[ndir3][1] )
								Endif
							Next ndir3
						Endif
					Next ndir2
				Endif
			Next ndir1
		Endif
		
		//Copia arquivos para o servidor
		fCpySrv( cDestinoOri + "systemload\" )

		// executar o job
		RnUpddistr(cNome)

		//Verifica o arquivo de retorno para iniciar outro pacote
		cStatus := LeArquivo()
		If cStatus == "2"
			lRet  := .T.
		elseif cStatus $ "1,3"
			lRet  := .F.
		EndIf

	endif
	
Return lRet


/*/{Protheus.doc} fCpySrv
Copia os arquivos da pasta temporaria para a systemload do sistema
@type function
@version 1.0
@author Ulisses Souza
@since 22/02/2022
@param cDirAux, character, Diretorio temporario
@return logical, Retorna se copiou todos os arquivos
/*/
Static Function fCpySrv( cDirAux )

	Local nAtual  := 0
	Local cDirSrv := GetSrvProfString("RootPath","") + __cSystemload
	Local aDirSrv := Directory(cDirSrv + "*.*","A")
	Local cDirBkp := GetSrvProfString("RootPath","") + __cSystemload + "upddistr-" + Left(StrTran(StrTran(FWTimeStamp(5,Date(),Time()),"-",""),":",""),15) + "\" 
	Local aDirAux := Directory(cDirAux + "*.txt","A")
	
	//Cria bkp Diretorio
	FwMakeDir(cDirBkp)
	
	//Percorre os arquivos e copia para pasta bkp somentes os arquivos do pacote
	For nAtual := 1 To Len(aDirSrv)
		cNomArq := lower(aDirSrv[nAtual][1])
		If "sdfbra.txt" == cNomArq .Or. "hlpdfpor.txt" == cNomArq
			//Copia o arquivo para a pasta do sistema
			__CopyFile( cDirSrv + cNomArq , cDirBkp + cNomArq )
		Endif
	Next nAtual

	CleanSystemLoad()

	//Percorre os arquivos
	For nAtual := 1 To Len(aDirAux)
		cNomArq := lower(aDirAux[nAtual][1])
		//Faz a copia do arquivo para a pasta do Systemload
		__CopyFile( cDirAux + cNomArq , __cSystemload + cNomArq )
	Next nAtual

Return


/*/{Protheus.doc} LeArquivo
Função para ler o arquivo no final do UpdDisttr
@type function
@version 1.0
@author Ulisses Souza
@since 22/02/2022
@return Character, Status do processo do upddistr
1 - Upddistr não Finalizado
2 - Upddistr Finalizado com sucesso
3 - Upddistr Finalizado com erro
/*/
Static function LeArquivo()

	Local oFile   := nil
	Local cStatus := "1" //Upddistr não Finalizado
	Local cFile   := GetSrvProfString("rootPath","") + __cSystemload + "result.json"
	Local oJson, uRet, aJson

	oFile := FWFileReader():New(cFile)

	if oFile:Open()
		cJson	:= oFile:FullRead()
		oFile:Close()
	Endif

	oJson	:= JsonObject():new()
	uRet	:= oJson:FromJson(cJson)
	If ValType(uRet) <> "U"
		Return cStatus
	Endif

	aJson := oJson:GetNames()
	oJson:GetJsonObject(aJson[1])
	If "success" $ lower(oJson:GetJsonObject(aJson[1]))
		cStatus := "2" //Upddistr Finalizado com sucesso
	Else
		cStatus := "3" //Upddistr Finalizado com erro
	Endif
	oJson := Nil
	
Return cStatus


/*
https://tdn.totvs.com/display/public/LMPING/UPDDISTR+executed+via+Job

[UPDJOB]
MAIN=UPDDISTR
ENVIRONMENT=P12

[ONSTART]
Jobs=UPDJOB
RefreshRate=900

2. Na pasta Systemload, crie um arquivo JSON chamado upddistr_param.json, com o seguinte conteúdo:

{
	"password"      : "senha",
	"simulacao"     : false,
	"localizacao"   : "BRA",
	"sixexclusive"  : true,
	"empresas"      : ["99","01","03"],
	"logprocess"    : false,
	"logatualizacao": false,
	"logwarning"    : false,
	"loginclusao"   : false,
	"logcritical"   : true,
	"updstop"       : false,
	"oktoall"       : true,
	"deletebkp"     : true,
	"keeplog"       : false
}

password       = Senha do usuário administrador
simulacao      = Habilita o modo simulação, onde nenhuma modificação é efetivada
localizacao    = País que deve ser utilizado
sixexclusive   = Utilizar o arquivo de índices por empresa
empresas       = Lista das empresas que serão migradas, separadas por vírgula
logprocess     = Log de Processo
logatualizacao = Log de Atualização
logwarning     = Log de Warning Error
loginclusao    = Log de Inclusão
logcritical    = Log de Critical Error
updstop        = Permite interromper processo durante execução
oktoall        = Corrigir error automaticamente
deletebkp      = Eliminar arquivos de backup ao término da atualização de cada tabela
keeplog        = Manter o arquivo de log existente
*/

Static Function GetSM0()
Local nI
Local cCodSM0
Local cArqSX2
Local aSM0 := {}
Local aRet := {}
OpenSm0()
aSM0 := FWAllGrpCompany()
For nI := 1 To Len(aSM0)
	cCodSM0 := aSM0[nI]
	cArqSX2 := "SX2"+cCodSM0+"0"
	// MPSysSqlName("SX2") // Retorna o nome fisico de uma tabela.
	If aScan(aRet, cCodSM0 ) == 0
		OpenSxs(,,,,cCodSM0,cArqSX2,"SX2",,.F.)
		If Select(cArqSX2) > 0
			aAdd(aRet,cCodSM0)
		Endif
	EndIf
	If Select(cArqSX2) > 0
		(cArqSX2)->(DbCloseArea())
	EndIf
Next nI
RpcClearEnv()
Return aRet


Static Function GetFill(cSM0)
Local aFill := {}
OpenSm0()
aFill := FWAllFilial(,,cSM0)
RpcClearEnv()
Return aFill


/*/{Protheus.doc} ToBrackets
@type Function
@author alessandro@farias.net.br
@since 26/02/2022
@version 1.0
/*/
Static Function ToBrackets(cString,cToken)
Local cRet     := ""
Default cString := ''
Default cToken  := ','
cRet := FormatIn(StrTran(cString,"'",''),cToken)
cRet := "["+Substr(cRet,2,Len(cRet))
cRet := Substr(cRet,1,Len(cRet)-1)+"]"
Return cRet


/*/{Protheus.doc} MakeJson
@type Function
@author alessandro@farias.net.br
@since 26/02/2022
@version 1.0
/*/
Static Function MakeJson(Systemload,SenhaUpd,Empresas)
Local cFile		:= Systemload + "upddistr_param.json"
Local cTexto	:= ""
Local nHdle
Local nN
cTexto += '{' + CRLF
cTexto += '   "password":"'+SenhaUpd+'",' + CRLF
cTexto += '   "simulacao":false,' + CRLF
cTexto += '   "localizacao":"BRA",' + CRLF
cTexto += '   "sixexclusive":true,' + CRLF
cTexto += '   "empresas":[' + CRLF
For nN:=1 To Len(Empresas)
	cTexto += '      "'+Empresas[nN]+'"' +iif(nN<Len(Empresas),',','')+ CRLF
Next nN
cTexto += '   ],' + CRLF
cTexto += '   "logprocess":false,' + CRLF
cTexto += '   "logatualizacao":false,' + CRLF
cTexto += '   "logwarning":false,' + CRLF
cTexto += '   "loginclusao":false,' + CRLF
cTexto += '   "logcritical":true,' + CRLF
cTexto += '   "updstop":false,' + CRLF
cTexto += '   "oktoall":true,' + CRLF
cTexto += '   "deletebkp":true,' + CRLF
cTexto += '   "keeplog":true' + CRLF
cTexto += '}' + CRLF
fErase(cFile)
nHdle := FCreate(cFile,0)
FWrite(nHdle,cTexto)
FClose(nHdle)
Return


/*/{Protheus.doc} DistrLogin
@type Function
@author alessandro@farias.net.br
@since 26/02/2022
@version 1.0
/*/
Static Function DistrLogin()
Local oBmp
Local oPanel
Local oDlg
Local cUser	:= Padr('Administrador',25)
Local cPsw	:= Space(20)
Local oOk
Local oCancel
Local lEndDlg	:= .F.

Private oMainWnd

DEFINE MSDIALOG oDlg FROM 000,000 TO 135,305 TITLE 'Autenticação' PIXEL OF oMainWnd

@ 000,000 BITMAP oBmp RESNAME 'APLOGO' SIZE 65,37 NOBORDER PIXEL
oBmp:Align := CONTROL_ALIGN_RIGHT

@ 000,000 MSPANEL oPanel OF oDlg
oPanel:Align := CONTROL_ALIGN_ALLCLIENT

@ 05,05 SAY 'Usuário' SIZE 60,07 OF oPanel PIXEL
@ 13,05 MSGET cUser SIZE 80,08 OF oPanel PIXEL When .F.

@ 28,05 SAY 'Senha' SIZE 53,07 OF oPanel PIXEL
@ 36,05 MSGET cPsw SIZE 80,08 PASSWORD OF oPanel PIXEL

DEFINE SBUTTON oOk FROM 53,27 TYPE 1 ENABLE OF oPanel PIXEL ACTION( iif( !VldLogin(Alltrim(cUser),Alltrim(cPsw)), MsgStop('Usuário não autorizado'),iif( logupd(cUser), (lEndDlg := .T.,oDlg:End()),Final('Cancelado!') ) ) ) 

DEFINE SBUTTON oCancel FROM 53,57 TYPE 2 ENABLE OF oPanel PIXEL ACTION (lEndDlg := .T.,Final('Cancelado pelo operador'))
ACTIVATE MSDIALOG oDlg CENTERED VALID lEndDlg

Return { Alltrim (cUser),Alltrim (cPsw) }


Static Function VldLogin(cUser,cPsw)
Local lRet	:= .F.
Local aRetUser
PswOrder(2) //1 ID; 2 Nome
If PswSeek(cUser,.T.)
	If ! PswName(cPsw)
		Final('Senha Invalida!')
	else
		aRetUser		:= PswRet(1)
		__cUserID	:= aRetUser[1][1]
		If FwIsAdmin(__cUserID)
			__cUserID := Nil
			lRet := .T.
		else
			Final('Usuario nao faz parte do grupo de administradores!')
		EndIf
	Endif
EndIf
Return lRet


Static function logupd(login)
// tratar no futuro 
Return .T.


Static Function PbRetSX
Local aRet := {}
aAdd(aRet,"SIX")
aAdd(aRet,"SX1")
aAdd(aRet,"SX2")
aAdd(aRet,"SX3")
aAdd(aRet,"SX5")
aAdd(aRet,"SX6")
aAdd(aRet,"SX7")
aAdd(aRet,"SX9")
aAdd(aRet,"SXA")
aAdd(aRet,"SXB")
aAdd(aRet,"SXD")
aAdd(aRet,"SXG")
aAdd(aRet,"SXQ")
aAdd(aRet,"SXR")
aAdd(aRet,"XAC")
aAdd(aRet,"XB3")
aAdd(aRet,"XBA")
aAdd(aRet,"XXA")
Return aRet


/*/{Protheus.doc} RnUpddistr
@type Function
@author alessandro@farias.net.br
@since 01/03/2022
@version 1.0
@example U_MontaSDF
/*/
Static Function RnUpddistr(cMsg)
FWMonitorMsg("PBUPD "+cMsg)
If LockByName( "RnUpddistr",.F.,.F.,.T. )
	StartJob("UPDDISTR", GetEnvServer(), .T.)
Endif
UnlockByName( "RnUpddistr",.F.,.F.,.T. )
Return


/*/{Protheus.doc} CleanSystemLoad
faz a limpeza do systemload
@type Function
@author alessandro@farias.net.br
@since 01/03/2022
@version 1.0
@example U_MontaSDF
/*/
Static Function CleanSystemLoad()
Local nDir1
Local aFiles

// limpeza dos pacotes antes de executar o pacote
aEval(Directory(__cSystemload +"sdf*.txt")  , { |aFiles| fErase(__cSystemload + aFiles[1]) })
aEval(Directory(__cSystemload +"hlpdf*.txt"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
aEval(Directory(__cSystemload +"sigah*.h*") , { |aFiles| fErase(__cSystemload + aFiles[1]) })

aEval(Directory(__cSystemload +"*.dtc"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
aEval(Directory(__cSystemload +"*.cdx"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
aEval(Directory(__cSystemload +"*.idx"), { |aFiles| fErase(__cSystemload + aFiles[1]) })

If __lInDB
	aFiles := PbRetSX()
	For nDir1:=1 To Len(aFiles)
		If TcCanOpen(aFiles[nDir1])
			TcDelFile(aFiles[nDir1])
		Endif
	Next nDir1
Endif

// limpeza antes de executar
If File(__cSystemload+"result.json")
	fErase(__cSystemload+"result.json")
Endif

//Apaga pasta de dicionarios extras
DirRemove(__cSystemload + "refedict") // só remove se estiver vazia

Return
