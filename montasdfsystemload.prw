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
User Function MontaSDF

	Local cOrigem  := ""
	Local cDestino := ""
	
	Local aDir1    := {}
	Local ndir1
	
	WfPrepEnv("99","01")
	
	cOrigem  := SuperGetMV("MV_XORIGEM" ,.F.,"C:\patch_totvs\")
	cDestino := SuperGetMV("MV_XDESTINO",.F.,"C:\TMPZIP\")
	
	FwMakeDir(cDestino)
	FwMakeDir(cOrigem + "processado\")
	FwMakeDir(cOrigem + "pendentes\")
	FwMakeDir(cOrigem + "erro\")
	
	aEval(Directory(cDestino +"systemload\*.*"), { |aFile| fErase(cDestino +"systemload\" + aFile[1]) })
	
	aDir1 := Directory(cOrigem + "\*.zip","A")
	
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
			
			aEval(Directory(cOrigem + "\*.*"), { |aFile| __CopyFile( cOrigem +aFile[1] , cOrigem + "pendentes\" + aFile[1]) })
			
			ndir1 := Len(aDir1)
			
		endif
		
	Next ndir1
	
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
