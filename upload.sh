# term egg forest panic canvas equip way artefact access lunar taste fringe

# wasmd keys add relayer --recover
# wasm1lwwr2junyeej0mts25rmjshqw2cw8w66mvpyle
# wasmd q bank balances wasm1lwwr2junyeej0mts25rmjshqw2cw8w66mvpyle --node http://localhost:26659
# -
# osmosis keys add relayer --recover
# osmo1lwwr2junyeej0mts25rmjshqw2cw8w66etrpqq
# osmosisd q bank balances osmo1lwwr2junyeej0mts25rmjshqw2cw8w66etrpqq --node http://localhost:26653
# -

# upload contracts, extra ones are from cw-plus

# cd to dirname of script
cd "$(dirname "$0")"

# pwd

export WASM_KEY="relayer"
export WASM_ADDR="wasm1lwwr2junyeej0mts25rmjshqw2cw8w66mvpyle"
export WASM_ARGS="--broadcast-mode sync --yes --output json --fees 50000ucosm --gas 3000000"




CW1_WHITELIST_TX=$(wasmd tx wasm store artifacts/cw1_whitelist.wasm --from $WASM_KEY --broadcast-mode sync $WASM_ARGS | jq -r '.txhash') && echo $CW1_WHITELIST_TX
CODE_ID_CW1=$(wasmd query tx $CW1_WHITELIST_TX --output json | jq -r '.logs[0].events[-1].attributes[0].value') && echo $CODE_ID_CW1
# we only need the code id for the host contract
# CW1_TX_UPLOAD=$(wasmd tx wasm instantiate "$CODE_ID_CW1" '{"admins": ["wasm1lwwr2junyeej0mts25rmjshqw2cw8w66mvpyle"], "mutable": true}' --label "cw1_whitelist" $WASM_ARGS --admin $WASM_ADDR --from $WASM_KEY | jq -r '.txhash') && echo $CW1_TX_UPLOAD
# CW1ADDR=$(wasmd query tx $CW1_TX_UPLOAD --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "CW1 Contract Addr: $CW1ADDR"
# wasm1wug8sewp6cedgkmrmvhl3lf3tulagm9hnvy8p0rppz9yjw0g4wtqhs9hr8

HOST_CONTRACT_TX=$(wasmd tx wasm store artifacts/simple_ica_host.wasm --from $WASM_KEY --broadcast-mode sync $WASM_ARGS | jq -r '.txhash') && echo $HOST_CONTRACT_TX
CODE_ID_HOST=$(wasmd query tx $HOST_CONTRACT_TX --output json | jq -r '.logs[0].events[-1].attributes[0].value') && echo $CODE_ID_HOST
export INIT_MSG=`printf '{"cw1_code_id": %d}' $CODE_ID_CW1`
HOST_TX_UPLOAD=$(wasmd tx wasm instantiate "$CODE_ID_HOST" "$INIT_MSG" --label "ica-host" $WASM_ARGS --admin $WASM_ADDR --from $WASM_KEY | jq -r '.txhash') && echo $HOST_TX_UPLOAD
HOST_ADDR=$(wasmd query tx $HOST_TX_UPLOAD --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "HOST ADDR: $HOST_ADDR"
# wasm1suhgf5svhu4usrurvxzlgn54ksxmn8gljarjtxqnapv8kjnp4nrss5maay

# on osmosis?
CONTROLLER_CONTRACT_TX=$(wasmd tx wasm store artifacts/simple_ica_controller.wasm --from $WASM_KEY --broadcast-mode sync $WASM_ARGS | jq -r '.txhash') && echo $CONTROLLER_CONTRACT_TX
CODE_ID_CONTROLLER=$(wasmd query tx $CONTROLLER_CONTRACT_TX --output json | jq -r '.logs[0].events[-1].attributes[0].value') && echo $CODE_ID_CONTROLLER
CONTROLLER_TX_UPLOAD=$(wasmd tx wasm instantiate "$CODE_ID_CONTROLLER" "{}" --label "ica-host" $WASM_ARGS --admin $WASM_ADDR --from $WASM_KEY | jq -r '.txhash') && echo $CONTROLLER_TX_UPLOAD
CONTROLLER_ADDR=$(wasmd query tx $CONTROLLER_TX_UPLOAD --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "Controller ADDR: $CONTROLLER_ADDR"
# 


wasmd tx wasm execute $HOST_ADDR '{"account": {"channel_id": "channel-0"}}'


wasmd q wasm contract-state smart $HOST_ADDR '{"account": {"channel_id": 0}}'
wasmd q wasm contract-state smart $HOST_ADDR '{"list_accounts": {}}'



