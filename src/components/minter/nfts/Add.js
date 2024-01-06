/* eslint-disable react/jsx-filename-extension */
import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button, Modal, Form, FloatingLabel } from "react-bootstrap";
import { uploadFileToWebStorage } from "../../../utils/minter";

// basic attributes that can be added to NFT
const TYPES = [
  "Histotical Figure",
  "Art and Culture",
  "Invention and Innovation",
  "Locations and Landmarks",
  "Mythodology and religion",
];
const EXCLUSIVITY = [
  "Imperators",
  "Legates",
  "Senators",
  "Centurions",
  "Tributes",
];
const PHYSICAL_INTEGRATION = ["Redeemable", "Personalized Memorabilia", "Authenticity Certificates", "Customized Art Prints"];

const AddNfts = ({ save, address }) => {
  const [name, setName] = useState("");
  const [ipfsImage, setIpfsImage] = useState("");
  const [description, setDescription] = useState("");

  //store attributes of an NFT
  const [attributes, setAttributes] = useState([]);
  const [show, setShow] = useState(false);

  // check if all form data has been filled
  const isFormFilled = () =>
    name && ipfsImage && description && attributes.length > 2;

  // close the popup modal
  const handleClose = () => {
    setShow(false);
    setAttributes([]);
  };

  // display the popup modal
  const handleShow = () => setShow(true);

  // add an attribute to an NFT
  const setAttributesFunc = (e, trait_type) => {
    const { value } = e.target;
    const attributeObject = {
      trait_type,
      value,
    };
    const arr = attributes;

    // check if attribute already exists
    const index = arr.findIndex((el) => el.trait_type === trait_type);

    if (index >= 0) {
      // update the existing attribute
      arr[index] = {
        trait_type,
        value,
      };
      setAttributes(arr);
      return;
    }

    // add a new attribute
    setAttributes((oldArray) => [...oldArray, attributeObject]);
  };

  return (
    <>
      <Button
        onClick={handleShow}
        variant="dark"
        className="rounded-pill px-0 d-flex justify-content-center "
        style={{ width: "130px" }}
      >
        <i className="bi bi-plus"></i> <span>Create NFT</span>
      </Button>

      {/* Modal */}
      <Modal show={show} onHide={handleClose} centered>
        <Modal.Header closeButton>
          <Modal.Title>Create NFT</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form>
            <FloatingLabel
              controlId="inputLocation"
              label="Name"
              className="mb-3"
            >
              <Form.Control
                type="text"
                placeholder="Name of NFT"
                onChange={(e) => {
                  setName(e.target.value);
                }}
              />
            </FloatingLabel>

            <FloatingLabel
              controlId="inputDescription"
              label="Description"
              className="mb-3"
            >
              <Form.Control
                as="textarea"
                placeholder="description"
                style={{ height: "80px" }}
                onChange={(e) => {
                  setDescription(e.target.value);
                }}
              />
            </FloatingLabel>

            <Form.Control
              type="file"
              className={"mb-3"}
              onChange={async (e) => {
                const imageUrl = await uploadFileToWebStorage(e);
                if (!imageUrl) {
                  alert("failed to upload image");
                  return;
                }
                setIpfsImage(imageUrl);
              }}
              placeholder="Product name"
            />
            <Form.Label>
              <h5>Properties</h5>
            </Form.Label>
            <Form.Control
              as="select"
              className={"mb-3"}
              onChange={async (e) => {
                setAttributesFunc(e, "Types");
              }}
              placeholder="Types"
            >
              <option hidden>Types</option>
              {TYPES.map((_types) => (
                <option
                  key={`background-${_types.toLowerCase()}`}
                  value={_types.toLowerCase()}
                >
                  {_types}
                </option>
              ))}
            </Form.Control>

            <Form.Control
              as="select"
              className={"mb-3"}
              onChange={async (e) => {
                setAttributesFunc(e, "Exclusivity");
              }}
              placeholder="NFT Exclusivity"
            >
              <option hidden>Exclusivity</option>
              {EXCLUSIVITY.map((_exclusivity) => (
                <option
                  key={`color-${_exclusivity.toLowerCase()}`}
                  value={_exclusivity.toLowerCase()}
                >
                  {_exclusivity}
                </option>
              ))}
            </Form.Control>

            <Form.Control
              as="select"
              className={"mb-3"}
              onChange={async (e) => {
                setAttributesFunc(e, "Physical Integration");
              }}
              placeholder="NFT Physical Integration"
            >
              <option hidden>Physical Integration</option>
              {PHYSICAL_INTEGRATION.map((physicalIntegration) => (
                <option
                  key={`PhysicalIntegration-${physicalIntegration.toLowerCase()}`}
                  value={physicalIntegration.toLowerCase()}
                >
                  {physicalIntegration}
                </option>
              ))}
            </Form.Control>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="outline-secondary" onClick={handleClose}>
            Close
          </Button>
          <Button
            variant="dark"
            disabled={!isFormFilled()}
            onClick={() => {
              save({
                name,
                ipfsImage,
                description,
                ownerAddress: address,
                attributes,
              });
              handleClose();
            }}
          >
            Create NFT
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
};

AddNfts.propTypes = {
  // props passed into this component
  save: PropTypes.func.isRequired,
  address: PropTypes.string.isRequired,
};

export default AddNfts;
