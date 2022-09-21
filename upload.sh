# https://github.com/Web3-Builders-Alliance/wba-mtw-testnet/blob/main/relayer/README.md

# term egg forest panic canvas equip way artefact access lunar taste fringe

# wasmd keys add relayer --recover --hd-path "m/44'/1234'/0'/2'" # 
# wasm18ef4ede5mscprrx3270flk9d0w4f2mppw3e6sc
# wasmd q bank balances wasm18ef4ede5mscprrx3270flk9d0w4f2mppw3e6sc --node http://localhost:26659
# -
# osmosis keys add relayer --recover
# osmo1lwwr2junyeej0mts25rmjshqw2cw8w66etrpqq
# osmosisd q bank balances osmo1lwwr2junyeej0mts25rmjshqw2cw8w66etrpqq --node http://localhost:26653
# -

# upload contracts, extra ones are from cw-plus

cd "$(dirname "$0")"

export WASM_KEY="relayer"
export WASM_ADDR="wasm18ef4ede5mscprrx3270flk9d0w4f2mppw3e6sc"
export WASM_ARGS="--broadcast-mode sync --yes --output json --fees 750000ucosm --gas 3000000"
export OSMOSIS_KEY="relayer"
export OSMOSIS_ADDR="osmo1lwwr2junyeej0mts25rmjshqw2cw8w66etrpqq"
export OSMOSIS_ARGS="--broadcast-mode sync --yes --output json --fees 50000uosmo --gas 3000000 --node http://localhost:26653 --chain-id osmo-testing"

CW1_WHITELIST_TX=$(wasmd tx wasm store artifacts/cw1_whitelist.wasm --from $WASM_KEY --broadcast-mode sync $WASM_ARGS | jq -r '.txhash') && echo $CW1_WHITELIST_TX
CODE_ID_CW1=$(wasmd query tx $CW1_WHITELIST_TX --output json | jq -r '.logs[0].events[-1].attributes[0].value') && echo $CODE_ID_CW1
# we only need the code id for the host contract
# CW1_TX_UPLOAD=$(wasmd tx wasm instantiate "$CODE_ID_CW1" '{"admins": ["wasm1lwwr2junyeej0mts25rmjshqw2cw8w66mvpyle"], "mutable": true}' --label "cw1_whitelist" $WASM_ARGS --admin $WASM_ADDR --from $WASM_KEY | jq -r '.txhash') && echo $CW1_TX_UPLOAD
# CW1ADDR=$(wasmd query tx $CW1_TX_UPLOAD --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "CW1 Contract Addr: $CW1ADDR"
# --

HOST_CONTRACT_TX=$(wasmd tx wasm store artifacts/simple_ica_host.wasm --from $WASM_KEY --broadcast-mode sync $WASM_ARGS | jq -r '.txhash') && echo $HOST_CONTRACT_TX
CODE_ID_HOST=$(wasmd query tx $HOST_CONTRACT_TX --output json | jq -r '.logs[0].events[-1].attributes[0].value') && echo $CODE_ID_HOST
export INIT_MSG=`printf '{"cw1_code_id": %d}' $CODE_ID_CW1`
HOST_TX_UPLOAD=$(wasmd tx wasm instantiate "$CODE_ID_HOST" "$INIT_MSG" --label "ica-host" $WASM_ARGS --admin $WASM_ADDR --from $WASM_KEY | jq -r '.txhash') && echo $HOST_TX_UPLOAD
HOST_ADDR=$(wasmd query tx $HOST_TX_UPLOAD --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "HOST ADDR: $HOST_ADDR"
# wasm1wug8sewp6cedgkmrmvhl3lf3tulagm9hnvy8p0rppz9yjw0g4wtqhs9hr8

# on osmosis?
CONTROLLER_CONTRACT_TX=$(osmosisd tx wasm store artifacts/simple_ica_controller.wasm --from $OSMOSIS_KEY --broadcast-mode sync $OSMOSIS_ARGS | jq -r '.txhash') && echo $CONTROLLER_CONTRACT_TX
CODE_ID_CONTROLLER=$(osmosisd query tx $CONTROLLER_CONTRACT_TX --output json --node http://localhost:26653 | jq -r '.logs[0].events[-1].attributes[0].value') && echo $CODE_ID_CONTROLLER
CONTROLLER_TX_UPLOAD=$(osmosisd tx wasm instantiate "$CODE_ID_CONTROLLER" "{}" --label "ica-host" $OSMOSIS_ARGS --admin $OSMOSIS_ADDR --from $OSMOSIS_KEY | jq -r '.txhash') && echo $CONTROLLER_TX_UPLOAD
CONTROLLER_ADDR=$(osmosisd query tx $CONTROLLER_TX_UPLOAD --output json --node http://localhost:26653 | jq -r '.logs[0].events[0].attributes[0].value') && echo "Controller ADDR: $CONTROLLER_ADDR"
# osmo14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9sq2r9g9

# == open a relay channel between both wasmd-1 and osmo-testing ==
ibc-setup init --src local_osmo --dest local_wasm
# # registery.yaml
# version: 1
# chains:
#   local_wasm:
#     chain_id: wasmd-1
#     prefix: wasm
#     gas_price: 0.025ucosm
#     hd_path: m/44'/1234'/0'/2'
#     estimated_block_time: 400
#     estimated_indexer_time: 60
#     rpc:
#       - http://localhost:26659
#   local_osmo:
#     chain_id: osmo-testing
#     prefix: osmo
#     gas_price: 0uosmo
#     hd_path: m/44'/118'/0'/0/0
#     estimated_block_time: 400
#     estimated_indexer_time: 60
#     rpc:
#       - http://localhost:26653

# update mnumonic to the one used used top of here
ibc-setup keys list

ibc-setup ics20 -v
ibc-relayer start -v --poll 2

# test IBC Tx
# osmosisd tx ibc-transfer transfer transfer channel-0 wasm18ef4ede5mscprrx3270flk9d0w4f2mppw3e6sc 72osmo --from osmo1lwwr2junyeej0mts25rmjshqw2cw8w66etrpqq --node http://localhost:26653 --chain-id osmo-testing --packet-timeout-height 0-0


# wasmd tx wasm execute $HOST_ADDR '{"account": {"channel_id": "channel-0"}}' --from $WASM_KEY $WASM_ARGS

# osmosisd tx wasm execute $CONTROLLER_ADDR '{"check_remote_balance": {"channel_id": "channel-0"}}' --from relayer $OSMOSIS_ARGS


# osmosisd tx wasm execute $CONTROLLER_ADDR '{"check_remote_balance": {"channel_id": "connection-0"}}' --from relayer $OSMOSIS_ARGS


wasmd q wasm contract-state smart $HOST_ADDR '{"account": {"channel_id": 0}}'
wasmd q wasm contract-state smart $HOST_ADDR '{"list_accounts": {}}'



