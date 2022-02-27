#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"

Static __cConsoleLg	:= GetPvProfString("GENERAL", "ConsoleFile", "console.log", GetAdv97())
Static __cSystemload	:= "\systemload\"

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
	Local lInDB
	Local aFiles

	****************** rodar -> FwRebuildIndex

	//OpenSM0Excl() //Realiza a abertura do dicionario Exclusivo para validar se ha alguem acessando
	//RpcClearEnv()
	
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
	lInDB		:= MPDicInDB()

	// limpeza antes de executar
	If File(__cSystemload+"result.json")
		fErase(__cSystemload+"result.json")
	Endif
	If File(__cSystemload+"upddistr_param.json")
		fErase(__cSystemload+"upddistr_param.json")
	Endif
	// ja cria o arquivo na pasta systemload
	MakeJson(__cSystemload,aLogin[02],cEmpresas)

	//RpcClearEnv()
	FERROU := StartJob("UPDDISTR", GetEnvServer(), .T.) // esta gerando erro no R33 
	RETURN

	ConOut("local do console.log -> "+__cConsoleLg)
	
	//cOrigem  := SuperGetMV("MV_XORIGEM" ,.F.,"c:\patch_totvs\")
	//cDestino := SuperGetMV("MV_XDESTINO",.F.,"c:\tmpzip\")
	
	FwMakeDir(cDestino)
	FwMakeDir(cOrigem + "processado\")
	FwMakeDir(cOrigem + "pendente\")
	FwMakeDir(cOrigem + "erro\")

	// limpeza antes de executar
	aEval(Directory(__cSystemload +"sdf*.txt"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
	aEval(Directory(__cSystemload +"hlpdf*.txt"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
	aEval(Directory(__cSystemload +"sigah*.h*"), { |aFiles| fErase(__cSystemload + aFiles[1]) })

	If ! lInDB
		aEval(Directory(__cSystemload +"*.dtc"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
		aEval(Directory(__cSystemload +"*.cdx"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
		aEval(Directory(__cSystemload +"*.idx"), { |aFiles| fErase(__cSystemload + aFiles[1]) })
	Else
		aFiles := PbRetSX()
		For nDir1:=1 To Len(aFiles)
			If TcCanOpen(aFiles[nDir1])
				TcDelFile(aFiles[nDir1])
			Endif
		Next nDir1
	Endif
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
			aEval(Directory(cOrigem + "\sdfbra.txt"), { |aFile| __CopyFile( cOrigem +aFile[1] , cOrigem + "pendentes\" + aFile[1]) })
			aEval(Directory(cOrigem + "\hlpdfpor.txt"), { |aFile| __CopyFile( cOrigem +aFile[1] , cOrigem + "pendentes\" + aFile[1]) })
			ndir1 := Len(aDir1)
		endif
		
	Next ndir1

	If File(__cSystemload+"upddistr_param.json")
		fErase(__cSystemload+"upddistr_param.json")
	Endif

Return

/*/{Protheus.doc} XListZip
Função para descompactar o arquivo zip na pasta temporaria
@type function
@version 12.1.23
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
		
		//Verifica o arquivo de retorno para iniciar outro pacote
		lCont := .T.
		while !lCont
			cStatus := LeArquivo()
			If cStatus == "2"
				lCont := .F.
				lRet  := .T.
				
			elseif cStatus == "3"
				lCont := .F.
				lRet  := .F.
				
			EndIf
		Enddo
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
	Local cDirSrv := GetSrvProfString("RootPath","") + "\systemload\"
	Local aDirSrv := Directory(cDirSrv + "*.*","A")
	
	Local cDirBkp := GetSrvProfString("RootPath","") + "\systemload-" + dtos(date()) + strtran(time(),":","-") + "\"
	Local aDirAux := Directory(cDirAux + "*.txt","A")
	Local lCont   := .T.
	
	//Cria bkp Diretorio
	FwMakeDir(cDirBkp)
	
	//Percorre os arquivos e copia para pasta BKp
	For nAtual := 1 To Len(aDirSrv)
		
		//Pegando o nome do arquivo
		cNomArq := aDirSrv[nAtual][1]
		
		//Copia o arquivo para a pasta do sistema
		__CopyFile( cDirSrv + cNomArq , cDirBkp + cNomArq )
		
	Next nAtual
	
	
	//Limpa pasta systemload
	while lCont
		aEval(Directory(cDirSrv +"*.txt"), { |aFile| fErase(cDirSrv + aFile[1]) })
		
		if len(  Directory(cDirSrv+"*.txt","A") ) == 0
			lCont := .F.
		endif
		
	enddo
	
	//Apaga arquivos de retorno do UpdDistr
	fErase(cDirSrv + "result.json")
	//Apaga pasta de dicionarios extras
	DirRemove(cDirSrv + "refedict")
	
	//Percorre os arquivos
	For nAtual := 1 To Len(aDirAux)
		
		//Pegando o nome do arquivo
		cNomArq := aDirAux[nAtual][1]
		
		//Copia o arquivo para a pasta do sistema
		lRet := __CopyFile( cDirAux + cNomArq , cDirSrv + cNomArq )
		
		if !lRet
			exit
		endif
		
	Next nAtual
	
Return lRet


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
	Local cLinha  := ""
	Local cStatus := "0"
	Local cFile   := GetSrvProfString("rootPath","") + "\systemload\" + "result.json"
	
	oFile := FWFileReader():New(cFile)
	
	if (oFile:Open())
		while (oFile:hasLine())
			cLinha := oFile:GetLine()
		end
		oFile:Close()
	endif
	
	if !Empty(cLinha)
		if !("success" $ cLinha)
			//Upddistr Finalizado com sucesso
			cStatus := "2"
		else
			//Upddistr Finalizado com erro
			cStatus := "3"
		endif
		
		//Upddistr não Finalizado
		cStatus := "1"
	endif
	
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
cTexto += '{'
cTexto += '"password":"'+SenhaUpd+'",'
cTexto += '"simulacao":false,'
cTexto += '"localizacao":"BRA",'
cTexto += '"sixexclusive":true,'
cTexto += '"empresas":'+Empresas+','
cTexto += '"logprocess":false,'
cTexto += '"logatualizacao":false,'
cTexto += '"logwarning":false,'
cTexto += '"loginclusao":false,'
cTexto += '"logcritical":true,'
cTexto += '"updstop":false,'
cTexto += '"oktoall":true,'
cTexto += '"deletebkp":true,'
cTexto += '"keeplog":true'
cTexto += '}'
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
Local cUser	:= Space(25)
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

@05,05 SAY 'Usuário' SIZE 60,07 OF oPanel PIXEL
@13,05 MSGET cUser SIZE 80,08 OF oPanel PIXEL

@28,05 SAY 'Senha' SIZE 53,07 OF oPanel PIXEL
@36,05 MSGET cPsw SIZE 80,08 PASSWORD OF oPanel PIXEL

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
aAdd(aRet,"SX1")
aAdd(aRet,"SX2")
aAdd(aRet,"SX3")
aAdd(aRet,"SX5")
aAdd(aRet,"SX6")
aAdd(aRet,"SX7")
aAdd(aRet,"SX9")
aAdd(aRet,"SXA")
aAdd(aRet,"SXB")
aAdd(aRet,"SXG")
aAdd(aRet,"SXQ")
aAdd(aRet,"SXR")
aAdd(aRet,"XXA")
aAdd(aRet,"SIX")
Return aRet
